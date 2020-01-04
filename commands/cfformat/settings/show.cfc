/**
 * Dump the formatting settings that will be used to format the specified
 * file or directory, based on your configured setting sources.
 *
 * {code:bash}
 * cfformat settings show path/to/MyComponent.cfc
 * cfformat settings show path/to/mycomponents/
 * cfformat settings show path/to/mycomponents/ ~/.cfformat.json
 * {code}
 *
 * Globs may be used when passing paths to cfformat.
 */
component accessors="true" {

    property cfformat inject="CFFormat@commandbox-cfformat";
    property cfformatUtils inject="cfformatutils@commandbox-cfformat";

    /**
     * @path component or directory path
     * @settingsPath path to a JSON settings file
     */
    function run(string path = '', string settingsPath = '') {
        var pathData = cfformatUtils.resolveFormatPath(path);

        if (path.len() && !pathData.filePaths.len()) {
            print.redLine(path & ' is not a valid file or directory.');
            return;
        }

        var userSettings = cfformatUtils.resolveSettings(pathData.filePaths, settingsPath);

        printSettings(userSettings, pathData.filePaths);
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

}
