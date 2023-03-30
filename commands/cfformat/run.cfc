/**
 * Formats script and tag components
 *
 * {code:bash}
 * cfformat run path/to/MyComponent.cfc
 * cfformat run path/to/mycomponents/
 * {code}
 *
 * Globs may be used when passing paths to cfformat.
 *
 */
component accessors="true" aliases="fmt" {

    property cfformat inject="CFFormat@commandbox-cfformat";
    property cfformatUtils inject="cfformatutils@commandbox-cfformat";
    property progressBarGeneric inject="progressBarGeneric";
    property tempDir inject="tempDir@constants";

    /**
     * @path component or directory path
     * @settingsPath path to a JSON settings file
     * @overwrite overwrite file in place
     * @timeit print the time formatting took to the console
     * @cfm format cfm files as well as cfc - use with caution, preferably on pure CFML cfm files
     * @staged Flag to run against staged files in git only. Overwrites `path` when used. Changes will also be staged.
     */
    function run(
        string path = '',
        string settingsPath = '',
        boolean overwrite = false,
        boolean timeit = false,
        boolean cfm = false,
        boolean staged = false
    ) {
        if (arguments.staged) {
            arguments.path = getStagedFiles();
            if (!arguments.path.len()) {
                print.yellowLine('No staged files to format.');
                return;
            }
            arguments.overwrite = true;
        }

        var pathData = cfformatUtils.resolveFormatPath(path, cfm);

        if (path.len() && !pathData.filePaths.len()) {
            print.redLine(path & ' is not a valid file or directory.');
            return;
        }

        var userSettings = cfformatUtils.resolveSettings(pathData.filePaths, settingsPath);

        if (pathData.pathType == 'file') {
            formatFile(
                pathData.filePaths[1],
                userSettings.paths[pathData.filePaths[1]],
                overwrite,
                timeit
            )
        } else {
            formatFiles(
                pathData.filePaths,
                userSettings.paths,
                overwrite,
                timeit
            );
        }

        if (arguments.staged) {
            commitFormattedStagedFiles(listToArray(arguments.path));
        }
    }

    function formatFile(fullPath, settings, overwrite, timeit) {
        var start = getTickCount();
        var formatted = cfformat.formatFile(fullPath, settings);
        var timeTaken = getTickCount() - start;

        if (overwrite) {
            fileWrite(fullPath, formatted, 'utf-8');
        } else {
            print.line(formatted);
        }

        if (timeit) {
            print.line();
            print.aquaLine('Formatting took ' & timeTaken & 'ms');
        }
    }

    function formatFiles(paths, settings, overwrite, timeit) {
        if (!overwrite) {
            overwrite = confirm(
                'Running `cfformat` on multiple files will overwrite your components in place. Are you sure? [y/n]'
            );
            if (!overwrite) {
                print.line('Aborting...');
                return;
            }
        }

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
                print.indentedLine(cfformatUtils.osPath(f));
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
            if (!success) {
                result.failures.append(file);
                logFile(file, false);
            } else {
                fileWrite(file, formatted, 'utf-8');
                logFile(file, true);
            }

            // NOTE: progress bar won't draw if shell is not interactive
            var percent = round(count / total * 100);
            progressBarGeneric.update(percent = percent, currentCount = count, totalCount = total);
        }

        var startMessage = 'Formatting files...';
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

        print.line('Files formatted: ' & result.count - result.failures.len());
        if (result.failures.len()) {
            printFailures('The following files were unable to be formatted:', result.failures);
        }

        if (timeit) {
            if (timeTaken > 1000) {
                var totalTime = numberFormat(timeTaken / 1000, '.00') & 's';
            } else {
                var totalTime = timeTaken & 'ms';
            }
            print.aquaLine('Formatting completed in ' & totalTime);
        }
    }

    function getGitApi() {
        if (!structKeyExists(variables, 'gitApi')) {
            var CWD = cfformatUtils.resolvePath('');
            var repoPath = CWD & '.git';

            var builder = createObject('java', 'org.eclipse.jgit.storage.file.FileRepositoryBuilder').init();
            var gitDir = createObject('java', 'java.io.File').init(repoPath);

            var repository = builder
                .setGitDir(gitDir)
                .setMustExist(true)
                .readEnvironment() // scan environment GIT_* variables
                .findGitDir() // scan up the file system tree
                .build();
            variables.gitApi = createObject('java', 'org.eclipse.jgit.api.Git').init(repository);
        }

        return variables.gitApi;
    }

    string function getStagedFiles() {
        var status = getGitApi().status().call();

        var filesToFormat = [];
        filesToFormat.append(status.getAdded().toArray(), true);
        filesToFormat.append(status.getChanged().toArray(), true);

        return arrayToList(filesToFormat);
    }

    void function commitFormattedStagedFiles(required array files) {
        var addCommand = getGitApi().add();
        for (var file in arguments.files) {
            addCommand.addFilepattern(file);
        }
        addCommand.call();
    }

}
