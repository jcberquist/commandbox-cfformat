/**
 * Display reference information for cfformat settings
 *
 * Pass a setting name or prefix to see reference
 * information only for that setting or prefix
 *
 * {code:bash}
 * cfformat settings info
 * cfformat settings info struct
 * {code}
 */
component accessors="true" {

    property cfformat inject="CFFormat@commandbox-cfformat";

    /**
     * @setting pass a setting name or prefix to get reference information
     * @setting.optionsUDF settingNames
     * @path component or directory path
     * @settingsPath path to a JSON settings file
     */
    function run(string setting = '') {
        var defaultSettings = cfformat.getDefaultSettings();
        var reference = cfformat.getReference();
        var examples = cfformat.getExamples();

        var info = reference
            .keyArray()
            .sort('text')
            .filter((k) => k.startswith(setting))
            .map((k) => {
                return {setting: k, reference: reference[k]}
            });

        for (var ref in info) {
            print.BlackOnGrey93Line(' #ref.setting# ');
            print.line(ref.reference.description);
            print.text('Default: ')
            print.blueLine(defaultSettings[ref.setting]);
            if (examples.keyExists(ref.setting)) {
                examples[ref.setting].each((option, example) => {
                    print.underscoredBlueLine(option);
                    print.line(example)
                    print.line().toConsole();
                });
            }
        }
    }

    array function settingNames() {
        return cfformat
            .getReference()
            .keyArray()
            .sort('text');
    }

}
