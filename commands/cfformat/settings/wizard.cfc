component {

    property name="fileSystemUtil" inject="FileSystem";
    property name='formatterUtil' inject='formatter';

    function run() {
        var examples = deserializeJSON(
            fileRead( expandPath( "/cfformat/data/examples.json" ) )
        );

        print.line();
        print.line( "Let me help you get started with your cfformat settings." );
        print.line( "I'll show you examples of each formatting option.  You choose the one you prefer." );
        print.line( "At the end, I'll generate a `.cfformat.json` for your project." );
        print.line( "Sound good?  Press any key to get started!" ).toConsole();
        waitForKey();

        var userSettings = examples.reduce( ( settings, name, options ) => {
            shell.clearScreen();

            print.blackOnYellowLine( name ).line();

            options.each( ( option, example ) => {
                print.underscoredBlueLine( option );
                print.line( example )
                print.line().toConsole();
            } );

            settings[ name ] = multiselect()
                .setQuestion( "Which style do you prefer? " )
                .setOptions(
                    options.keyArray().map( ( option ) => ( { "value" = option } ) )
                )
                .setRequired( true )
                .setMultiple( false )
                .ask();

            return settings;
        }, [:] );

        shell.clearScreen();
        print.line( "Great! Let's save these settings off to a file." );
        print.line( "Where should I save the file?" ).toConsole();
        var filePath = ask( message = "", defaultResponse = ".cfformat.json" );

        fileSystemUtil.lockingFileWrite(
            fileSystemUtil.resolvePath( filePath ),
            formatterUtil.formatJson( serializeJSON( userSettings ) )
        );

        print.line().boldDarkGreenOnWhiteLine( " All done!  Enjoy your automatically formatted life! " );
    }

}
