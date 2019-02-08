/**
* Formats script and tag components
*
* {code:bash}
* cfformat path/to/MyComponent.cfc
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
    */
    function run(
        string path,
        string settingsPath = '',
        boolean overwrite = false,
        boolean timeit = false,
        boolean settings = false
    ) {
        var userSettings = getUserSettings(settingsPath);

        if (isNull(userSettings)) return;

        if (settings) {
            userSettings.settings.append(cfformat.getDefaultSettings(), false);
            if (userSettings.sources.len()) {
                print.line('User setting sources:');
                for (var source in userSettings.sources) {
                    print.indentedGreenLine(source);
                }
                print.line().toConsole();
            }
            print.line(userSettings.settings);
            return;
        }

        var fullPath = resolvePath(path);
        if (fileExists(fullPath)) {
            formatFile(
                fullPath,
                userSettings.settings,
                overwrite,
                timeit
            );
        } else if (directoryExists(fullPath)) {
            formatDirectory(
                fullPath,
                userSettings.settings,
                overwrite,
                timeit
            );
        } else {
            print.redLine(fullPath & ' is not a valid file or directory.');
        }
    }

    function getUserSettings(inlineSettingsPath) {
        var userSettingsPaths = [configService.getSetting('cfformat.settings', ''), inlineSettingsPath];

        var userSettings = {sources: [], settings: {}};

        for (var path in userSettingsPaths) {
            if (path.len()) {
                var fullPath = resolvePath(path);
                if (!fileExists(fullPath)) {
                    print.redLine(fullPath & ' does not exist.');
                    return;
                }
                userSettings.sources.append(fullPath);
                userSettings.settings.append(deserializeJSON(fileRead(fullPath)));
            }
        }
        return userSettings;
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

    function formatDirectory(
        fullPath,
        userSettings,
        overwrite,
        timeit
    ) {
        if (!overwrite) {
            overwrite = confirm(
                'Running `cfformat` on a directory will overwrite your components in place. Are you sure? [y/n]'
            );
            if (!overwrite) {
                print.line('Aborting...');
                return;
            }
        }

        job.start('Formatting components in #fullPath#...', 10);

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
        var result = cfformat.formatDirectory(
            fullPath,
            fullTempPath,
            userSettings,
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

}
