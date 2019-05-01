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
        var userSettings = getUserSettings(path, settingsPath);

        if (isNull(userSettings)) return;

        if (settings) {
            if (userSettings.sources.len()) {
                print.line('User setting sources:');
                for (var source in userSettings.sources) {
                    print.indentedGreenLine(source);
                }
                print.line().toConsole();
            }
            var fullSettings = cfformat.mergedSettings(userSettings.settings);
            print.line(fullSettings);
            return;
        }

        if (!path.len() && !arguments.watch) {
            command('cfformat help').run();
            return;
        }

        var fullPath = resolvePath(path);
        if ( arguments.watch ) {
            var processorCount = createObject( "java", "java.lang.Runtime" ).getRuntime().availableProcessors();
            this.watch()
                .paths( "**.cfc" )
                .inDirectory( fullPath )
                .onChange( function( files ) {
                    var allFiles = files.added.append( files.changed, true );
                    allFiles.each( function( filePath ) {
                        var formatCommand = command( "cfformat" )
                            .params( path = filePath )
                            .flags( "overwrite" )
                            .params( settingsPath = settingsPath )
                            .run();
                    }, true, processorCount );
                    print.line( "Formatting complete!" ).toConsole();
                } )
                .start();
        } else {
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
    }

    function getUserSettings(path, inlineSettingsPath) {
        var userSettings = {sources: [], settings: {}};

        var addSettings = function(path, fail = false) {
            var fullPath = resolvePath(path);
            if (userSettings.sources.find(fullPath)) return;
            if (fileExists(fullPath)) {
                userSettings.sources.append(fullPath);
                userSettings.settings.append(deserializeJSON(fileRead(fullPath)));
            } else if (fail) {
                print.redLine(fullPath & ' does not exist.');
                return;
            }
        }

        addSettings(configService.getSetting('cfformat.settings', '~/.cfformat.json'));

        if (path.len()) {
            var formatDir = getDirectoryFromPath(resolvePath(path)).replace('\', '/', 'all');
            while (formatDir.listLen('/') > 0) {
                if (fileExists(formatDir & '/.cfformat.json')) {
                    addSettings(formatDir & '/.cfformat.json');
                    break;
                } else if (directoryExists(formatDir & '/.git/')) {
                    break;
                }
                formatDir = formatDir.listDeleteAt(formatDir.listLen('/'), '/');
            }
        }

        if (inlineSettingsPath.len()) {
            addSettings(inlineSettingsPath, true);
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
