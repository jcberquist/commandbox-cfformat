/**
 * Check to see if the file(s) are formatted according to your
 * rules without making any changes
 *
 * {code:bash}
 * cfformat check path/to/MyComponent.cfc
 * cfformat check path/to/mycomponents/
 * {code}
 *
 * Globs may be used when passing paths to cfformat.
 *
 */
component accessors="true" {

    property cfformat inject="CFFormat@commandbox-cfformat";
    property cfformatUtils inject="cfformatutils@commandbox-cfformat";
    property progressBarGeneric inject="progressBarGeneric";
    property tempDir inject="tempDir@constants";

    /**
     * @path component or directory path
     * @settingsPath path to a JSON settings file
     * @overwrite overwrite file in place
     * @timeit print the time formatting took to the console
     * @verbose print the file diff to the console when check fails,
     * @cfm format cfm files as well as cfc - use with caution, preferably on pure CFML cfm files
     */
    function run(
        string path = '',
        string settingsPath = '',
        boolean timeit = false,
        boolean verbose = false,
        boolean cfm = false
    ) {
        var pathData = cfformatUtils.resolveFormatPath(path, cfm);

        if (path.len() && !pathData.filePaths.len()) {
            print.redLine(path & ' is not a valid file or directory.');
            return;
        }

        var userSettings = cfformatUtils.resolveSettings(pathData.filePaths, settingsPath);

        if (pathData.pathType == 'file') {
            checkFile(
                pathData.filePaths[1],
                userSettings.paths[pathData.filePaths[1]],
                timeit,
                verbose
            );
        } else {
            checkFiles(
                pathData.filePaths,
                userSettings.paths,
                timeit,
                verbose,
                cfm
            );
        }
    }

    function checkFile(fullPath, settings, timeit, verbose) {
        var start = getTickCount();
        var formatted = cfformat.formatFile(fullPath, settings);
        var timeTaken = getTickCount() - start;

        var original = fileRead(fullPath, 'utf-8');
        if (compare(original, cfformatUtils.stripBOM(formatted)) == 0) {
            print.greenLine('File is formatted according to cfformat rules.');
        } else {
            print.redLine('File is not formatted according to cfformat rules.');
            if (verbose) {
                printDiff(diff(original, formatted), true);
            }
        }

        if (timeit) {
            print.line();
            print.aquaLine('Check took ' & timeTaken & 'ms');
        }
    }

    function checkFiles(paths, settings, timeit, verbose, cfm) {
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
                if (verbose) {
                    printDiff(f.diffString);
                }
            }
            print.line();
        }

        var cb = function(
            file,
            formatted,
            success,
            message,
            count,
            total
        ) {
            result.count++;
            if (success) {
                var original = fileRead(file, 'utf-8');
                if (compare(original, cfformatUtils.stripBOM(formatted)) == 0) {
                    logFile(file, true);
                } else {
                    result.failures.append({file: file, diffString: verbose ? diff(original, formatted) : ''});
                    logFile(file, false);
                }
            } else {
                result.failures.append({file: file, diffString: ''});
                logFile(file, false);
            }

            // NOTE: progress bar won't draw if shell is not interactive
            var percent = round(count / total * 100);
            progressBarGeneric.update(percent = percent, currentCount = count, totalCount = total);
        }

        var startMessage = 'Checking component formatting...';
        if (interactive) {
            job.start(startMessage, 10);
        } else {
            print.line(startMessage).toConsole();
        }

        var start = getTickCount();
        cfformat.formatFiles(paths, fullTempPath, settings, cb, cfm);
        var timeTaken = getTickCount() - start;
        setExitCode(min(result.failures.len(), 1));

        if (interactive) {
            if (result.failures.len()) {
                job.error(dumpLog = true);
            } else {
                job.complete(true);
            }
        }

        print.line('Files checked: ' & result.count);
        print.line();
        if (result.failures.len()) {
            printFailures('The following files do not match the cfformat rules:', result.failures);
            print.line('Please format the files using the `--overwrite` flag.');
        }

        if (timeit) {
            if (timeTaken > 1000) {
                var totalTime = numberFormat(timeTaken / 1000, '.00') & 's';
            } else {
                var totalTime = timeTaken & 'ms';
            }
            print.aquaLine('Check completed in ' & totalTime);
        }
    }

    private function printDiff(diffString, interactive) {
        if (interactive) {
            for (var line in reMatch('[^\r\n]*\r?\n', diffString)) {
                if (line.startsWith('+')) {
                    print.greenText(line);
                } else if (line.startsWith('-')) {
                    print.redText(line);
                } else if (line.startsWith('@@')) {
                    print.blueText(line);
                } else {
                    print.text(line);
                }
            }
            print.line();
        } else {
            print.line(diffString);
        }
    }

    private function diff(source, formatted) {
        var differ = createObject('java', 'org.eclipse.jgit.diff.HistogramDiff').init();
        var comparator = createObject('java', 'org.eclipse.jgit.diff.RawTextComparator').DEFAULT;
        var rawSource = createObject('java', 'org.eclipse.jgit.diff.RawText').init(source.getBytes());
        var rawFormatted = createObject('java', 'org.eclipse.jgit.diff.RawText').init(formatted.getBytes());
        var out = createObject('java', 'java.io.ByteArrayOutputStream').init();
        var formatter = createObject('java', 'org.eclipse.jgit.diff.DiffFormatter').init(out);
        formatter.setContext(1);
        var edits = differ.diff(comparator, rawSource, rawFormatted);
        formatter.format(edits, rawSource, rawFormatted);
        return out.toString();
    }

}
