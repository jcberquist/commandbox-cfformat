/**
* Formats script and tag components
*
* {code:bash}
* cfformat path/to/MyComponent.cfc
* cfformat path/to/mycomponents/
* {code}
*
*/
component accessors="true" {

    property cfformat inject="CFFormat@commandbox-cfformat";
    property interactiveJob inject="interactiveJob";
    property progressBarGeneric inject="progressBarGeneric";
    property tempDir inject="tempDir@constants";

    /**
    * @path component or directory path
    * @settingsPath path to a JSON settings file
    * @overwrite overwrite file in place
    * @timeit print the time formatting took to the console
    * @settings dump cfformat settings to the console
    * @watch enter into a watch mode on the path and format any files changed
    */
    function run(
        string path = '',
        string settingsPath = '',
        boolean overwrite = false,
        boolean timeit = false,
        boolean settings = false,
        boolean watch = false
    ) {
        var paths = resolvePaths(path);

        if (path.len() && !paths.len()) {
            print.redLine(path & ' is not a valid file or directory.');
            return;
        }

        var userSettings = resolveSettings(paths, settingsPath);

        if (settings) {
            printSettings(userSettings, paths);
            return;
        }

        if (arguments.watch) {
            var processorCount = createObject('java', 'java.lang.Runtime').getRuntime().availableProcessors();
            this.watch()
                .paths('**.cfc')
                .inDirectory(paths.len() == 1 ? paths[1] : getCWD())
                .onChange(function(files) {
                    var start = getTickCount();
                    var allFiles = files.added.append(files.changed, true);
                    allFiles.each(
                        function(filePath) {
                            var formatCommand = command('cfformat')
                                .params(path = filePath)
                                .flags('overwrite')
                                .params(settingsPath = settingsPath)
                                .run();
                        },
                        true,
                        processorCount
                    );
                    print.line('Formatting complete!').toConsole();
                })
                .start();
            return;
        }

        if (!paths.len()) {
            command('cfformat help').run();
        } else if (paths.len() == 1) {
            formatFile(
                paths[1],
                userSettings.pathSettings[paths[1]].settings,
                overwrite,
                timeit
            );
        } else {
            var pathSettings = userSettings.pathSettings.map((k, v) => v.settings ?: v);
            formatFiles(
                paths,
                pathSettings,
                overwrite,
                timeit
            );
        }
    }

    function resolvePaths(pathSource) {
        return pathSource
            .listToArray(chr(10))
            .reduce((r, p) => {
                var matches = globber(resolvePath(p.trim())).matches();
                for (var match in matches) {
                    if (directoryExists(match)) {
                        r.append(directoryList(match, true, 'path', '*.cfc'), true)
                    } else {
                        r.append(match);
                    }
                }

                return r;
            }, []);
    }

    function resolveSettings(paths, inlineSettingsPath) {
        var settings = {baseSettingsPath: '', inlineSettingsPath: '', pathSettings: {}};
        var dirCache = {};

        var baseSettingsPath = resolvePath(configService.getSetting('cfformat.settings', '~/.cfformat.json'));
        if (fileExists(baseSettingsPath)) {
            settings.baseSettingsPath = baseSettingsPath;
            settings.pathSettings[baseSettingsPath] = deserializeJSON(fileRead(baseSettingsPath));
        }

        if (inlineSettingsPath.len()) {
            inlineSettingsPath = resolvePath(inlineSettingsPath);
            if (!fileExists(inlineSettingsPath)) {
                throw(inlineSettingsPath & ' is not a valid path.');
            }
            settings.inlineSettingsPath = inlineSettingsPath;
            settings.pathSettings[inlineSettingsPath] = deserializeJSON(fileRead(inlineSettingsPath));
        }

        for (var path in paths) {
            var pathSettings = {sources: [], settings: {}};
            if (settings.baseSettingsPath.len()) {
                pathSettings.sources.append(settings.baseSettingsPath);
                pathSettings.settings.append(settings.pathSettings[settings.baseSettingsPath]);
            }

            var formatDir = getDirectoryFromPath(path).replace('\', '/', 'all');
            var seen = [];
            var directorySettings = {};

            while (formatDir.listLen('/') > 0) {
                seen.append(formatDir);
                var fullPath = formatDir & server.separator.file & '.cfformat.json';

                if (dirCache.keyExists(formatDir)) {
                    directorySettings = dirCache[formatDir];
                    if (directorySettings.isEmpty()) break;
                } else if (fileExists(fullPath)) {
                    directorySettings = deserializeJSON(fileRead(fullPath));
                }

                if (!directorySettings.isEmpty()) {
                    pathSettings.sources.append(fullPath);
                    pathSettings.settings.append(directorySettings);
                    break;
                } else if (directoryExists(formatDir & '/.git/')) {
                    break;
                }

                formatDir = formatDir.listDeleteAt(formatDir.listLen('/'), '/');
            }

            seen.each((p) => pathCache[p] = directorySettings);

            if (settings.inlineSettingsPath.len()) {
                pathSettings.sources.append(settings.inlineSettingsPath);
                pathSettings.settings.append(settings.pathSettings[settings.inlineSettingsPath]);
            }

            settings.pathSettings[path] = pathSettings;
        }

        return settings;
    }

    function formatFile(
        fullPath,
        userSettings,
        overwrite,
        timeit
    ) {
        if (!fullPath.endsWith('.cfc')) {
            print.yellowLine(fullPath & ' is not a component. `cfformat` only works on `.cfc` files.');
            return;
        }

        var start = getTickCount();
        var formatted = cfformat.formatFile(fullPath, userSettings);
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

    function formatFiles(
        paths,
        pathSettings,
        overwrite,
        timeit
    ) {
        if (!overwrite) {
            overwrite = confirm(
                'Running `cfformat` on multiple files will overwrite your components in place. Are you sure? [y/n]'
            );
            if (!overwrite) {
                print.line('Aborting...');
                return;
            }
        }

        job.start('Formatting components...', 10);

        var tempKey = createUUID().lcase();
        var fullTempPath = resolvePath(tempDir & '/' & tempKey & '/');

        var start = getTickCount();
        var dumpLog = false;

        var cb = function(file, success, count, total) {
            dumpLog = dumpLog || !success;
            if (success) {
                job.addSuccessLog(file);
            } else {
                job.addErrorLog(file);
            }

            var percent = round(count / total * 100);
            progressBarGeneric.update(percent = percent, currentCount = count, totalCount = total);
        }
        var result = cfformat.formatFiles(
            paths,
            fullTempPath,
            pathSettings,
            cb
        );
        var timeTaken = getTickCount() - start;

        if (dumpLog) {
            job.error('Formatting completed with errors.', true);
        } else {
            job.complete();
        }

        if (timeit) {
            print.line();
            if (timeTaken > 1000) {
                var totalTime = numberFormat(timeTaken / 1000, '.00') & 's';
            } else {
                var totalTime = timeTaken & 'ms';
            }
            print.aquaLine('Formatting took ' & totalTime);
        }
    }

    function printSettings(settings, paths) {
        var userSettings = {};

        if (paths.len() == 1) {
            var pathSettings = settings.pathSettings[paths[1]];
            userSettings = pathSettings.settings;
            if (pathSettings.sources.len()) {
                print.line('User setting sources:');
                for (var source in pathSettings.sources) {
                    print.indentedGreenLine(source);
                }
            }
        } else if (settings.baseSettingsPath.len() || settings.inlineSettingsPath.len()) {
            print.line('User setting sources:');
            for (var key in ['baseSettingsPath', 'inlineSettingsPath']) {
                if (settings[key].len()) {
                    userSettings.append(settings.pathSettings[settings[key]]);
                    print.indentedGreenLine(settings[key]);
                }
            }
        }

        print.line(cfformat.mergedSettings(userSettings));
    }

}
