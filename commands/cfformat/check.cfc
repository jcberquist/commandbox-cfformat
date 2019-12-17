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
     */
    function run(string path = '', string settingsPath = '', boolean timeit = false) {
        var pathData = cfformatUtils.resolveFormatPath(path);

        if (path.len() && !pathData.filePaths.len()) {
            print.redLine(path & ' is not a valid file or directory.');
            return;
        }

        var userSettings = cfformatUtils.resolveSettings(pathData.filePaths, settingsPath);

        if (pathData.pathType == 'file') {
            checkFile(fullPath, userSettings.paths[fullPath], timeit)
        } else {
            checkFiles(pathData.filePaths, userSettings.paths, timeit);
        }
    }

    function checkFile(fullPath, settings, timeit) {
        var start = getTickCount();
        var formatted = cfformat.formatFile(fullPath, settings);
        var timeTaken = getTickCount() - start;

        var original = fileRead(fullPath, 'utf-8');
        if (compare(original, formatted) == 0) {
            print.greenLine('File is formatted according to cfformat rules.');
        } else {
            print.redLine('File is not formatted according to cfformat rules.');
        }

        if (timeit) {
            print.line();
            print.aquaLine('Check took ' & timeTaken & 'ms');
        }
    }

    function checkFiles(paths, settings, timeit) {
        var interactive = shell.isTerminalInteractive();
        var fullTempPath = resolvePath(tempDir & '/' & createUUID().lcase() & '/');
        var result = {count: 0, failures: []};

        var logFile = function(file, success) {
            if (interactive) {
                if (success) {
                    job.addSuccessLog(file);
                } else {
                    job.addErrorLog(file);
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
                print.indentedLine(f);
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
                if (compare(original, formatted) == 0) {
                    logFile(file, true);
                } else {
                    result.failures.append(file);
                    logFile(file, false);
                }
            } else {
                result.failures.append(file);
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
        cfformat.formatFiles(paths, fullTempPath, settings, cb);
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

}
