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
     */
    function run(
        string path = '',
        string settingsPath = '',
        boolean overwrite = false,
        boolean timeit = false
    ) {
        var paths = path.listToArray().map((p) => p & (p.endswith('.cfc') ? '' : '**.cfc'));

        this.watch()
            .paths(argumentCollection = paths)
            .onChange((files) => {
                // files could contain absolute paths
                var allFiles = files.added.append(files.changed, true).map((p) => fileExists(p) ? p : shell.pwd() & p);
                var userSettings = cfformatUtils.resolveSettings(allFiles, settingsPath);
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

}
