/**
 * Formats script and tag components that are unstaged for commit in Git
 *
 * {code:bash}
 * cfformat git unstaged
 * cfformat git unstaged path/to/git/directory
 * {code}
 */
component accessors="true" aliases="fmt-unstaged" {

    property cfformat inject="CFFormat@commandbox-cfformat";
    property cfformatUtils inject="cfformatutils@commandbox-cfformat";
    property progressBarGeneric inject="progressBarGeneric";
    property tempDir inject="tempDir@constants";

    /**
     * @directory git directory path to format unstaged files
     * @settingsPath path to a JSON settings file
     * @timeit print the time formatting took to the console
     * @cfm format cfm files as well as cfc - use with caution, preferably on pure CFML cfm files
     */
    function run(
        string directory = '',
        string settingsPath = '',
        boolean timeit = false,
        boolean cfm = false
    ) {
        var gitApi = buildGitApi(arguments.directory);
        var path = getUnstagedFiles(gitApi);

        if (!path.len()) {
            print.yellowLine('No modified or untracked files to format.');
            return;
        }

        var pathData = cfformatUtils.resolveFormatPath(path, cfm);

        if (path.len() && !pathData.filePaths.len()) {
            print.redLine(path & ' is not a valid file or directory.');
            return;
        }

        var userSettings = cfformatUtils.resolveSettings(pathData.filePaths, settingsPath);

        if (pathData.pathType == 'file') {
            formatFile(
                fullPath = pathData.filePaths[1],
                settings = userSettings.paths[pathData.filePaths[1]],
                timeit = timeit
            )
        } else {
            formatFiles(
                paths = pathData.filePaths,
                settings = userSettings.paths,
                timeit = timeit
            );
        }
    }

    function formatFile(fullPath, settings, timeit) {
        var start = getTickCount();
        var formatted = cfformat.formatFile(fullPath, settings);
        var timeTaken = getTickCount() - start;

        fileWrite(fullPath, formatted, 'utf-8');

        if (timeit) {
            print.line();
            print.aquaLine('Formatting took ' & timeTaken & 'ms');
        }
    }

    function formatFiles(paths, settings, timeit) {
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

    function buildGitApi(string directory = '') {
        var resolvedDirectory = cfformatUtils.resolvePath(arguments.directory);
        var repoPath = resolvedDirectory & '.git';

        if (!directoryExists(repoPath)) {
            error( "[#resolvedDirectory#] is not a git project." );
        }

        var builder = createObject('java', 'org.eclipse.jgit.storage.file.FileRepositoryBuilder').init();
        var gitDir = createObject('java', 'java.io.File').init(repoPath);

        var repository = builder
            .setGitDir(gitDir)
            .setMustExist(true)
            .readEnvironment() // scan environment GIT_* variables
            .findGitDir() // scan up the file system tree
            .build();
        return createObject('java', 'org.eclipse.jgit.api.Git').init(repository);
    }

    string function getUnstagedFiles(required gitApi) {
        var status = arguments.gitApi.status().call();

        var filesToFormat = [];
        filesToFormat.append(status.getModified().toArray(), true);
        filesToFormat.append(status.getUntracked().toArray(), true);

        return arrayToList(filesToFormat);
    }

}
