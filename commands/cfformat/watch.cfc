/**
 * Watches a directory for component changes and format them.
 *
 * {code:bash}
 * cfformat watch path/to/mycomponents/
 * {code}
 *
 * Globs may be used when passing paths to cfformat.
 */
component accessors="true" extends="run" aliases="" {

    /**
     * @path component or directory path
     * @settingsPath path to a JSON settings file
     * @overwrite overwrite file in place
     * @timeit print the time formatting took to the console
     * @cfm format cfm files as well as cfc - use with caution, preferably on pure CFML cfm files
     */
    function run(
        string path = '',
        string settingsPath = '',
        boolean overwrite = false,
        boolean timeit = false,
        boolean cfm = false
    ) {
        var paths = path
            .listToArray(',', true)
            .map((p) => {
                var globEnding = '**.cf?';
                if (p.endswith('.cfc') || (cfm && p.endswith('.cfm'))) {
                    globEnding = '';
                }

                p = p.replace('\', '/', 'all');

                if (p.startsWith('./')) {
                    p = p.mid(3, p.len() - 2);
                } else if (p == '.') {
                    p = p.mid(2, p.len() - 1);
                }

                return p & globEnding;
            });

        this.watch()
            .paths(argumentCollection = paths)
            .onChange((files) => {
                // files could contain absolute paths
                var allFiles = files.added
                    .append(files.changed, true)
                    .map((p) => {
                        p = fileExists(p) ? p : shell.pwd() & p;
                        return p.replace('\', '/', 'all');
                    });

                // filter files based on cfm setting
                allFiles = allFiles.filter((p) => {
                    return p.endswith('.cfc') || (cfm && p.endswith('.cfm'));
                });

                if (allFiles.len() == 0) {
                    return;
                }

                var userSettings = cfformatUtils.resolveSettings(allFiles, settingsPath);

                if (allFiles.len() == 1) {
                    print.text('Formatting ');
                    print.greenLine(cfformatutils.osPath(allFiles[1])).toConsole();
                    print.line('Setting sources:');
                    for (var source in userSettings.sources[allFiles[1]]) {
                        print.indentedYellowLine(cfformatutils.osPath(source)).toConsole();
                    }
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
                print.line().toConsole();
            })
            .start();
    }

}
