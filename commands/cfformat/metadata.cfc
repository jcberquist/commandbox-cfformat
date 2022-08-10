/**
 * Parses components and provides metadata similar to the getComponentMetadata() BIF
 *
 * {code:bash}
 * cfformat metadata path/to/MyComponent.cfc
 * cfformat metadata path/to/mycomponents/
 * {code}
 *
 * Globs may be used when passing paths to cfformat metadata.
 *
 */
component accessors="true" {

    property cfformat inject="CFFormat@commandbox-cfformat";
    property cfformatUtils inject="cfformatutils@commandbox-cfformat";
    property tempDir inject="tempDir@constants";

    /**
     * @path component or directory path
     * @timeit print the time parsing took to the console
     */
    function run(string path = '', boolean timeit = false) {
        var pathData = cfformatUtils.resolveFormatPath(path, false);

        if (path.len() && !pathData.filePaths.len()) {
            print.redLine(path & ' is not a valid file or directory.');
            return;
        }

        if (pathData.pathType == 'file') {
            parseFile(pathData.filePaths[1], timeit);
        } else {
            parseFiles(pathData.filePaths, timeit);
        }
    }

    function parseFile(fullPath, timeit) {
        var start = getTickCount();

        try {
            print.line(cfformat.metadata.parseFile(fullPath));
        } catch (any e) {
            print.redLine(e.message);
        }

        if (timeit) {
            var timeTaken = getTickCount() - start;
            print.line();
            print.aquaLine('Metadata parsing took ' & timeTaken & 'ms');
        }
    }

    function parseFiles(paths, timeit) {
        var start = getTickCount();
        var fullTempPath = resolvePath(tempDir & '/' & createUUID().lcase() & '/');

        try {
            var metadata = cfformat.metadata.parseFiles(paths, fullTempPath);
            var timeTaken = getTickCount() - start;
            print.line(metadata);
        } catch (any e) {
            print.redLine(e.message);
        }

        if (timeit) {
            if (timeTaken > 1000) {
                var totalTime = numberFormat(timeTaken / 1000, '.00') & 's';
            } else {
                var totalTime = timeTaken & 'ms';
            }
            print.aquaLine('Metadata parsing completed in ' & totalTime);
        }

    }

}
