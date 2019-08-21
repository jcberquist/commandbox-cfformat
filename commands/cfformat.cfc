/**
 * Formats script and tag components
 *
 * {code:bash}
 * cfformat path/to/MyComponent.cfc
 * cfformat path/to/mycomponents/
 * {code}
 *
 * Use the --watch flag with a directory to have it watch that directory
 * for component changes and format them.
 *
 * {code:bash}
 * cfformat ./ --watch
 * {code}
 *
 * Call it with the --settings flag to dump the formatting settings to the console.
 * If a file path is specified as well, it will show the settings that will be used
 * to format that particular file, based on your configured setting sources.
 *
 * {code:bash}
 * cfformat --settings
 * cfformat --settings > ~/.cfformat.json
 * cfformat path/to/MyComponent.cfc --settings
 * {code}
 *
 * Call it with `settingInfo` and a setting name or prefix to see reference
 * information for those settings
 *
 * {code:bash}
 * cfformat settingInfo=array
 * {code}
 *
 * Use the --check flag to have cfformat check to see if the file(s) are
 * formatted according to its rules without making any changes
 *
 * {code:bash}
 * cfformat ./ --check
 * {code}
 */
component accessors="true" {

    property cfformat inject="CFFormat@commandbox-cfformat";
    property interactiveJob inject="interactiveJob";
    property progressBarGeneric inject="progressBarGeneric";
    property tempDir inject="tempDir@constants";

    /**
     * @path component or directory path
     * @settingsPath path to a JSON settings file
     * @settingInfo pass a setting name or prefix to get reference information
     * @settingInfo.optionsUDF settingNames
     * @overwrite overwrite file in place
     * @timeit print the time formatting took to the console
     * @settings dump cfformat settings to the console
     * @watch enter into a watch mode on the path and format any files changed
     * @check check to see if updates would take place without actually making any
     */
    function run(
        string path = '',
        string settingsPath = '',
        string settingInfo = '',
        boolean overwrite = false,
        boolean timeit = false,
        boolean settings = false,
        boolean watch = false,
        boolean check = false
    ) {
        var fullPath = resolvePath(path);

        if (settingInfo.len()) {
            var defaultSettings = cfformat.getDefaultSettings();
            var reference = cfformat.getReference();
            var examples = cfformat.getExamples();

            var info = reference
                .keyArray()
                .sort('text')
                .filter((k) => k.startswith(settingInfo))
                .map((k) => {
                    return {setting: k, reference: reference[k]}
                });

            for (var ref in info) {
                print.BlackOnGrey93Line(' #ref.setting# ');
                print.line(ref.reference.description);
                print.text('Default: ')
                print.blueLine(defaultSettings[ref.setting]);
                if (examples.keyExists(ref.setting)) {
                    print.line();
                    print.line(examples[ref.setting]);
                }
            }
            return;
        }

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
                check,
                timeit
            )
        } else {
            formatFiles(
                filePaths,
                userSettings.paths,
                overwrite,
                check,
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
                // files could contain absolute paths
                var allFiles = files.added.append(files.changed, true).map((p) => fileExists(p) ? p : fullPath & p);
                var userSettings = resolveSettings(allFiles, settingsPath);
                if (allFiles.len() == 1) {
                    formatFile(
                        allFiles[1],
                        userSettings.paths[allFiles[1]],
                        true,
                        false,
                        true
                    )
                } else {
                    formatFiles(
                        allFiles,
                        userSettings.paths,
                        true,
                        false,
                        true
                    );
                }
                print.line('Formatting complete!').toConsole();
            })
            .start();
    }

    function resolveFilePaths(fullPath, pathType) {
        if (pathType == 'file') return [fullPath];

        if (pathType == 'dir') {
            var pathGlobs = [fullPath & '**.cfc'];
        } else {
            var pathGlobs = fullPath
                .listToArray(chr(10) & ',')
                .map((p) => {
                    var glob = resolvePath(p.trim());
                    if (directoryExists(glob)) glob &= '**.cfc';
                    return glob;
                });
        }

        var paths = [];
        pathGlobs.each((g) => {
            globber(g)
                .matches()
                .each((m) => {
                    if (m.lcase().endswith('.cfc') && !paths.find(m)) {
                        paths.append(m);
                    }
                })
        });
        return paths;
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

    function formatFile(
        fullPath,
        settings,
        overwrite,
        check,
        timeit
    ) {
        var start = getTickCount();
        var formatted = cfformat.formatFile(fullPath, settings);
        var timeTaken = getTickCount() - start;

        if (check) {
            var original = fileRead(fullPath, 'utf-8');
            if (compare(original, formatted) == 0) {
                print.greenLine('File is formatted according to cfformat rules.');
            } else {
                print.redLine('File is not formatted according to cfformat rules.');
            }
        } else if (overwrite) {
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
        settings,
        overwrite,
        check,
        timeit
    ) {
        if (!check && !overwrite) {
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
            if (!success) {
                result.failures.append(file);
                logFile(file, false);
            } else if (check) {
                var original = fileRead(file, 'utf-8');
                if (compare(original, formatted) == 0) {
                    logFile(file, true);
                } else {
                    result.failures.append(file);
                    logFile(file, false);
                }
            } else {
                fileWrite(file, formatted, 'utf-8');
                logFile(file, true);
            }

            // NOTE: progress bar won't draw if shell is not interactive
            var percent = round(count / total * 100);
            progressBarGeneric.update(percent = percent, currentCount = count, totalCount = total);
        }

        var startMessage = check ? 'Checking component formatting...' : 'Formatting components...';
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

        if (check) {
            print.line('Files checked: ' & result.count);
            print.line();
            if (result.failures.len()) {
                printFailures('The following files do not match the cfformat rules:', result.failures);
                print.line('Please format the files using the `--overwrite` flag.');
            }
        } else {
            print.line('Files formatted: ' & result.count - result.failures.len());
            if (result.failures.len()) {
                printFailures('The following files were unable to be formatted:', result.failures);
            }
        }

        if (timeit) {
            if (timeTaken > 1000) {
                var totalTime = numberFormat(timeTaken / 1000, '.00') & 's';
            } else {
                var totalTime = timeTaken & 'ms';
            }
            print.aquaLine('#check ? 'Check' : 'Formatting'# completed in ' & totalTime);
        }
    }

    function printSettings(settings, paths) {
        var userSettings = {};

        if (paths.len() && settings.sources[paths[1]].len()) {
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

        // flush buffer
        print.text().toConsole();

        try {
            print.line(cfformat.mergedSettings(userSettings));
        } catch (CFFormat.settings.validation e) {
            print.redLine(e.message);
        }
    }

    array function settingNames() {
        return cfformat
            .getReference()
            .keyArray()
            .sort('text');
    }

}
