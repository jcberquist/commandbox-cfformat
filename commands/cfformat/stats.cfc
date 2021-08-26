/**
 * Check to see if the tags in the file(s) are balanced
 *
 * {code:bash}
 * cfformat tag-check path/to/MyComponent.cfc
 * cfformat tag-check path/to/mycomponents/
 * {code}
 *
 * Globs may be used when passing paths to cfformat tag-check.
 *
 */
component accessors="true" {

    property cfformat inject="CFFormat@commandbox-cfformat";
    property cfformatUtils inject="cfformatutils@commandbox-cfformat";
    property progressBarGeneric inject="progressBarGeneric";
    property tempDir inject="tempDir@constants";

    /**
     * @path component or directory path
     * @timeit print the time the check took to the console
     */
    function run(string path = '', boolean timeit = false) {
        var pathData = cfformatUtils.resolveFormatPath(path, true);

        if (path.len() && !pathData.filePaths.len()) {
            print.redLine(path & ' is not a valid file or directory.');
            return;
        }

        if (pathData.pathType == 'file') {
            singleFileStats(pathData.filePaths[1], timeit);
        } else {
            fileStats(pathData.filePaths, timeit);
        }
    }

    function singleFileStats(fullPath, timeit) {
        var start = getTickCount();
        try {
            print.line(cfformat.stats.singleFileStats(fullPath));
        } catch (any e) {
            print.redLine(e.message);
        }
        var timeTaken = getTickCount() - start;

        if (timeit) {
            print.line();
            print.aquaLine('Stats run took ' & timeTaken & 'ms');
        }
    }

    function fileStats(paths, timeit) {
        var interactive = shell.isTerminalInteractive();
        var fullTempPath = resolvePath(tempDir & '/' & createUUID().lcase() & '/');
        var result = {count: 0, failures: []};

        var logFile = function(file, success) {
            if (interactive) {
                if (success) {
                    job.addSuccessLog(cfformatUtils.osPath(file));
                } else {
                    job.addErrorLog(cfformatUtils.osPath(file));
                }
            }
        }

        var printFailures = function(message, failures) {
            if (interactive) {
                print.redLine(message);
            } else {
                print.line(message);
            }
            print.line();
            for (var f in failures) {
                print.yellowLine(cfformatUtils.osPath(f.file));
                print.redLine(f.message);
                print.line();
            }
        }

        var cb = function(file, success, message, count, total) {
            result.count++;
            if (success) {
                logFile(file, true);
            } else {
                result.failures.append({file: file, message: message});
                logFile(file, false);
            }

            // NOTE: progress bar won't draw if shell is not interactive
            var percent = round(count / total * 100);
            progressBarGeneric.update(percent = percent, currentCount = count, totalCount = total);
        }

        var startMessage = 'Collecting stats...';
        if (interactive) {
            job.start(startMessage, 10);
        } else {
            print.line(startMessage).toConsole();
        }

        var start = getTickCount();
        var stats = cfformat.stats.fileStats(paths, fullTempPath, cb);
        var timeTaken = getTickCount() - start;
        setExitCode(min(result.failures.len(), 1));

        if (interactive) {
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
                components: 0,
                templates: 0,
                lines: 0,
                loc: 0,
                methods: 0,
                tags: {},
                bifs: {},
                functioncalls: {},
                methodcalls: {},
                functioncallcount: 0,
                methodcallcount: 0
            }
        );

        print.line('Total files: ' & result.count);
        print.line('Lines: ' & numberFormat(globalStats.lines, ','));
        print.line('Lines of Code: ' & numberFormat(globalStats.loc, ','));
        if (globalStats.templates) {
            print.line('Templates: ' & numberFormat(globalStats.templates, ','));
        }
        if (globalStats.components) {
            print.line('Components: ' & numberFormat(globalStats.components, ','));
            if (globalStats.methods) {
                print.line('Methods: ' & numberFormat(globalStats.methods, ','));
                print.line('Methods/Component: ' & numberFormat(globalStats.methods / globalStats.components, '.00'));
            }
        }

        print.line();
        print.line('Function calls: ' & numberFormat(globalStats.functioncallcount, ','));
        print.line('Method calls: ' & numberFormat(globalStats.methodcallcount, ','));

        print.line();
        print.line('Tag usage:');
        for (var tag in globalStats.tags.sort('numeric', 'desc')) {
            print.line('    #tag#: ' & numberFormat(globalStats.tags[tag], ','));
        }

        print.line();
        print.line('BIF usage:');
        for (var bif in globalStats.bifs.sort('numeric', 'desc')) {
            print.line('    #bif#: ' & numberFormat(globalStats.bifs[bif], ','));
        }

        if (result.failures.len()) {
            printFailures('The following files have errors:', result.failures);
        }

        if (timeit) {
            if (timeTaken > 1000) {
                var totalTime = numberFormat(timeTaken / 1000, '.00') & 's';
            } else {
                var totalTime = timeTaken & 'ms';
            }
            print.aquaLine('Stats collected in ' & totalTime);
        }
    }

}
