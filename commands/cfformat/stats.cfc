/**
 * Provide statistics on your codebase including number of files, lines of code, and count of BIFs/Tags in use.
 *
 * {code:bash}
 * cfformat stats path/to/MyComponent.cfc
 * cfformat stats path/to/mycomponents/
 * {code}
 *
 * Globs may be used when passing paths to cfformat stats.
 *
 */
component accessors="true" {

    property cfformat inject="CFFormat@commandbox-cfformat";
    property cfformatUtils inject="cfformatutils@commandbox-cfformat";
    property progressBarGeneric inject="progressBarGeneric";
    property tempDir inject="tempDir@constants";

    /**
     * @path component or directory path
     * @verbose Print out all files processed and all BIF/Tag usage
     * @JSON Output data in parsable JSON format
     */
    function run(string path = '', boolean verbose = false, boolean JSON = false) {
        var pathData = cfformatUtils.resolveFormatPath(path, true);

        if (path.len() && !pathData.filePaths.len()) {
            print.redLine(path & ' is not a valid file or directory.');
            return;
        }

        if (pathData.pathType == 'file') {
            singleFileStats(pathData.filePaths[1]);
        } else {
            fileStats(pathData.filePaths, verbose, JSON);
        }
    }

    function singleFileStats(fullPath) {
        var start = getTickCount();
        try {
            print.line(cfformat.stats.singleFileStats(fullPath));
        } catch (any e) {
            print.redLine(e.message);
        }
        var timeTaken = getTickCount() - start;

        print.line();
        print.aquaLine('Stats run took ' & timeTaken & 'ms');
    }

    function fileStats(paths, boolean verbose = false, boolean JSON = false) {
        var fullTempPath = resolvePath(tempDir & '/' & createUUID().lcase() & '/');
        var result = {count: 0, failures: []};

        var logFile = function(file, success) {
            if (JSON) {
                return;
            }
            if (success) {
                job.addSuccessLog(cfformatUtils.osPath(file));
            } else {
                job.addErrorLog(cfformatUtils.osPath(file));
            }
        }

        var printFailures = function(message, failures) {
            print.redLine(message);
            print.line();
            for (var f in failures) {
                print.yellowLine(cfformatUtils.osPath(f.file));
                print.redLine(f.message);
                print.line();
            }
        }

        var cb = function(file, success, message, count, total) {
            result.count++;
            if (!success) {
                result.failures.append({file: file, message: message});
            }

            if (JSON) {
                return;
            }

            logFile(file, success);
            // NOTE: progress bar won't draw if shell is not interactive
            var percent = round(count / total * 100);
            progressBarGeneric.update(percent = percent, currentCount = count, totalCount = total);
        }


        if (!JSON) {
            job.start('Collecting stats...', 10);
            if (verbose) {
                job.setDumpLog(verbose);
            }
        }

        var start = getTickCount();
        var stats = cfformat.stats.fileStats(paths, fullTempPath, cb);
        var timeTaken = getTickCount() - start;
        setExitCode(min(result.failures.len(), 1));

        if (!JSON) {
            if (result.failures.len()) {
                job.error(dumpLog = true);
            } else {
                job.complete();
            }
        }

        var globalStats = stats.reduce(
            (r, fp, s) => {
                if (fp.endswith('.cfc')) {
                    r.components++;
                }
                if (fp.endswith('.cfm')) {
                    r.templates++;
                }
                r.lines += s.lines;
                r.loc += s.loc;
                r.methods += s.methods.len();
                r.properties += s.properties.len();
                for (
                    var k in [
                        'tags',
                        'bifs',
                        'functioncalls',
                        'methodcalls'
                    ]
                ) {
                    for (var i in s[k]) {
                        r[k][i] = (r[k][i] ?: 0) + s[k][i];
                    }
                }

                r.functioncallcount += (
                    s.bifs.reduce((t = 0, k, v) => t += v) +
                    s.functioncalls.reduce((t = 0, k, v) => t += v)
                );
                r.methodcallcount += s.methodcalls.reduce((t = 0, k, v) => t += v);

                return r;
            },
            {
                'totalFiles': result.count,
                'timeTakenms': timeTaken,
                'failures': result.failures,
                'components': 0,
                'templates': 0,
                'lines': 0,
                'loc': 0,
                'methods': 0,
                'properties': 0,
                'tags': {},
                'bifs': {},
                'functioncalls': {},
                'methodcalls': {},
                'functioncallcount': 0,
                'methodcallcount': 0
            }
        );

        if (JSON) {
            print.line(globalStats);
        } else {
            prettyPrintResults(globalStats, verbose);
        }
    }

    private function prettyPrintResults(globalStats, boolean verbose = false) {
        print
            .line('Total files: ' & globalStats.totalFiles)
            .line('Lines: ' & numberFormat(globalStats.lines, ','))
            .line('Lines of Code: ' & numberFormat(globalStats.loc, ','));
        if (globalStats.templates) {
            print.line('Templates: ' & numberFormat(globalStats.templates, ','));
        }
        if (globalStats.components) {
            print.line('Components: ' & numberFormat(globalStats.components, ','));
            if (globalStats.methods) {
                print
                    .line('Methods: ' & numberFormat(globalStats.methods, ','))
                    .line('Methods/Component: ' & numberFormat(globalStats.methods / globalStats.components, '.00'));
            }
            if (globalStats.properties) {
                print
                    .line('Properties: ' & numberFormat(globalStats.properties, ','))
                    .line(
                        'Properties/Component: ' & numberFormat(globalStats.properties / globalStats.components, '.00')
                    );
            }
        }

        print
            .line()
            .line('Function calls: ' & numberFormat(globalStats.functioncallcount, ','))
            .line('Method calls: ' & numberFormat(globalStats.methodcallcount, ','));


        print.line().boldLine('Tag usage:');
        var count = 0;
        for (var tag in globalStats.tags.sort('numeric', 'desc')) {
            count++;
            if (count > 10 && !verbose) {
                print.line('    View #globalStats.tags.count() - 10# more with --verbose');
                break;
            }
            print.line('    #tag#: ' & numberFormat(globalStats.tags[tag], ','));
        }

        print.line().boldLine('BIF usage:');

        var count = 0;
        for (var bif in globalStats.bifs.sort('numeric', 'desc')) {
            count++;
            if (count > 10 && !verbose) {
                print.line('    View #globalStats.bifs.count() - 10# more with --verbose');
                break;
            }
            print.line('    #bif#: ' & numberFormat(globalStats.bifs[bif], ','));
        }

        if (globalStats.failures.len()) {
            printFailures('The following files have errors:', globalStats.failures);
        }

        if (globalStats.timeTakenms > 1000) {
            var totalTime = numberFormat(globalStats.timeTakenms / 1000, '.00') & 's';
        } else {
            var totalTime = globalStats.timeTakenms & 'ms';
        }

        print.aquaLine('Stats collected in ' & totalTime);
    }

}
