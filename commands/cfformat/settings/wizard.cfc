/**
 * Generate a settings file
 *
 * {code:bash}
 * cfformat settings wizard
 * {code}
 */
component {

    property cfformat inject="CFFormat@commandbox-cfformat";
    property fileSystemUtil inject="FileSystem";
    property formatterUtil inject="formatter";

    function run() {
        var defaultSettings = cfformat.getDefaultSettings();
        var reference = cfformat.getReference();
        var examples = cfformat.getExamples();

        print.line();
        print.line('Let me help you get started with your cfformat settings.');
        print.line('I''ll show you examples of each formatting option.  You choose the one you prefer.');
        print.line('The default values for each setting are pre-entered.');
        print.line('At the end, I''ll generate a `.cfformat.json` for your project.');
        print.line('Sound good?  Press any key to get started!').toConsole();
        waitForKey();

        var userSettings = reference.reduce((settings, name, options) => {
            shell.clearScreen();

            print
                .blackOnYellowLine(name)
                .line(options.description)
                .line()
                .toConsole();

            if (examples.keyExists(name)) {
                examples[name].each((option, example) => {
                    print.underscoredBlueLine(option);
                    print.line(example)
                    print.line().toConsole();
                });
            }

            switch (options.type) {
                case 'integer':
                    settings[name] = toNumeric(
                        ask(message = 'Enter integer value: ', defaultResponse = defaultSettings[name])
                    );
                    break;
                case 'boolean':
                    settings[name] = multiselect()
                        .setQuestion('Enable this? ')
                        .setOptions([
                            {display: 'true', value: true, selected: defaultSettings[name]},
                            {display: 'false', value: false, selected: !defaultSettings[name]}
                        ])
                        .setRequired(true)
                        .setMultiple(false)
                        .ask();
                    break;
                case 'struct-key-value':
                    settings[name] = multiselect()
                        .setQuestion('Struct Separator')
                        .setOptions(
                            examples[name]
                                .keyArray()
                                .map((choice) => (
                                    {
                                        display: serializeJSON(choice),
                                        value: choice,
                                        selected: choice == defaultSettings[name]
                                    }
                                ))
                        )
                        .setRequired(true)
                        .setMultiple(false)
                        .ask();
                    break;
                case 'string':
                    settings[name] = multiselect()
                        .setQuestion('Which style do you prefer? ')
                        .setOptions(
                            options.values.map((choice) => (
                                {
                                    display: serializeJSON(choice),
                                    value: choice,
                                    selected: choice == defaultSettings[name]
                                }
                            ))
                        )
                        .setRequired(true)
                        .setMultiple(false)
                        .ask();
            }

            return settings;
        }, [:]);

        shell.clearScreen();
        print.line('Great! Let''s save these settings off to a file.');
        print.line('Where should I save the file?').toConsole();
        var filePath = ask(message = '', defaultResponse = '.cfformat.json');

        fileSystemUtil.lockingFileWrite(
            fileSystemUtil.resolvePath(filePath),
            formatterUtil.formatJson(serializeJSON(userSettings))
        );

        print.line().boldDarkGreenOnWhiteLine(' All done!  Enjoy your automatically formatted life! ');
    }

}
