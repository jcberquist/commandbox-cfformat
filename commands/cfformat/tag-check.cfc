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
            checkFile(pathData.filePaths[1], timeit);
        } else {
            checkFiles(pathData.filePaths, timeit);
        }
    }

    function checkFile(fullPath, timeit) {
        var start = getTickCount();
        try {
            cfformat.tagcheck.checkFile(fullPath);
            print.greenLine('Tags are balanced.');
        } catch (any e) {
            print.redLine(e.message);
        }
        var timeTaken = getTickCount() - start;

        if (timeit) {
            print.line();
            print.aquaLine('Check took ' & timeTaken & 'ms');
        }
    }

    function checkFiles(paths, timeit) {
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
                print.yellowLine(f.file);
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

        var startMessage = 'Checking tags...';
        if (interactive) {
            job.start(startMessage, 10);
        } else {
            print.line(startMessage).toConsole();
        }

        var start = getTickCount();
        cfformat.tagcheck.checkFiles(paths, fullTempPath, cb);
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
            printFailures('The following files have errors:', result.failures);
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
