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
        var fullPath = resolvePath(path);

        if (arguments.watch) {
            watchDirectory(fullPath, settingsPath);
            return;
        }

        if (!path.len() && !settings) {
            command('cfformat help').run();
            return;
        }

        var pathType = 'glob';
        if (directoryExists(fullPath)) {
            pathType = 'dir';
        } else if (fileExists(fullPath)) {
            pathType = 'file';
            if (!fullPath.endsWith('.cfc')) {
                print.yellowLine(fullPath & ' is not a component. `cfformat` only works on `.cfc` files.');
                return;
            }
        }

        var filePaths = resolveFilePaths(fullPath, pathType);

        if (path.len() && !filePaths.len()) {
            print.redLine(path & ' is not a valid file or directory.');
            return;
        }

        var userSettings = resolveSettings(filePaths, settingsPath);

        if (settings) {
            printSettings(userSettings, filePaths);
            return;
        }

        if (pathType == 'file') {
            formatFile(
                fullPath,
                userSettings.paths[fullPath],
                overwrite,
                timeit
            )
        } else {
            formatFiles(
                filePaths,
                userSettings.paths,
                overwrite,
                timeit
            );
        }
    }

    function watchDirectory(fullPath, settingsPath) {
        if (!directoryExists(fullPath)) {
            print.redLine(fullPath & ' is not a valid directory');
            return;
        }

        this.watch()
            .paths('**.cfc')
            .inDirectory(fullPath)
            .onChange((files) => {
                var allFiles = files.added.append(files.changed, true).map((p) => fullPath & p);
                var userSettings = resolveSettings(allFiles, settingsPath);
                if (allFiles.len() == 1) {
                    formatFile(
                        allFiles[1],
                        userSettings.paths[allFiles[1]],
                        true,
                        true
                    )
                } else {
                    formatFiles(
                        allFiles,
                        userSettings.paths,
                        true,
                        true
                    );
                }
                print.line('Formatting complete!').toConsole();
            })
            .start();
    }

    function resolveFilePaths(fullPath, pathType) {
        if (pathType == 'file') return [fullPath];
        if (pathType == 'dir') fullPath &= '**';
        return globber(fullPath).matches().filter((m) => m.lcase().endswith('.cfc'));
    }

    function resolveSettings(paths, inlineSettingsPath) {
        var settings = {
            config: {},
            inline: {},
            sources: {},
            paths: {}
        };

        // CommandBox config settings
        var configPath = resolvePath(configService.getSetting('cfformat.settings', '~/.cfformat.json'));
        if (fileExists(configPath)) {
            settings.config = {path: configPath, settings: deserializeJSON(fileRead(configPath))};
        }

        // inline settings
        if (inlineSettingsPath.len()) {
            inlineSettingsPath = resolvePath(inlineSettingsPath);
            if (!fileExists(inlineSettingsPath)) {
                throw(inlineSettingsPath & ' is not a valid path.');
            }
            settings.inline = {path: inlineSettingsPath, settings: deserializeJSON(fileRead(inlineSettingsPath))};
        }

        // per path settings
        var settingsCache = {dirs: {}, settings: {}}
        for (var path in paths) {
            settings.paths[path] = {};
            settings.sources[path] = [];

            if (!settings.config.isEmpty()) {
                settings.paths[path].append(settings.config.settings);
                settings.sources[path].append(settings.config.path);
            }

            var formatDir = getDirectoryFromPath(path).replace('\', '/', 'all');
            var pathSettings = findSettings(formatDir, settingsCache);
            if (!pathSettings.isEmpty()) {
                settings.paths[path].append(pathSettings.settings);
                settings.sources[path].append(pathSettings.path);
            }

            if (!settings.inline.isEmpty()) {
                settings.paths[path].append(settings.inline.settings);
                settings.sources[path].append(settings.inline.path);
            }
        }

        return settings;
    }

    function findSettings(formatDir, settingsCache = {dirs: {}, settings: {}}) {
        var dirsChecked = [];

        while (formatDir.listLen('/') > 0) {
            var fullPath = formatDir & '.cfformat.json';
            dirsChecked.append(formatDir);

            if (settingsCache.dirs.keyExists(formatDir)) {
                var settingsPath = settingsCache.dirs[formatDir];
                dirsChecked.each((d) => settingsCache.dirs[d] = settingsPath);
                if (!settingsPath.len()) return {};
                return {path: settingsPath, settings: settingsCache.settings[settingsPath]}
            }

            if (fileExists(fullPath)) {
                settingsCache.settings[fullPath] = deserializeJSON(fileRead(fullPath));
                dirsChecked.each((d) => settingsCache.dirs[d] = fullPath);
                return {path: fullPath, settings: settingsCache.settings[fullPath]}
            }

            if (directoryExists(formatDir & '/.git/')) {
                break;
            }

            formatDir = formatDir.listDeleteAt(formatDir.listLen('/'), '/') & '/';
        }

        // didn't find any settings, note this in the cache
        dirsChecked.each((d) => settingsCache.dirs[d] = '');
        return {};
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
        var result = cfformat.formatFiles(paths, fullTempPath, settings, cb);
        var timeTaken = getTickCount() - start;

        if (dumpLog) {
            job.error('Formatting completed with errors.', true);
        } else {
            job.complete(true);
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

        if (paths.len() == 1 && settings.sources[paths[1]].len()) {
            userSettings = settings.paths[paths[1]];
            print.line('User setting sources:');
            for (var source in settings.sources[paths[1]]) {
                print.indentedGreenLine(source);
            }
        } else if (settings.config.len() || settings.inline.len()) {
            print.line('User setting sources:');
            for (var key in ['config', 'inline']) {
                if (settings[key].len()) {
                    print.indentedGreenLine(settings[key].path);
                    userSettings.append(settings[key].settings);
                }
            }
        }

        print.line(cfformat.mergedSettings(userSettings));
    }

}
