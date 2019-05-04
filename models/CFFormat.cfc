component accessors="true" {

    property rootFolder;
    property defaultSettings;
    property executable;

    function init(required string binFolder, required string rootFolder) {
        variables.rootFolder = arguments.rootFolder;
        variables.defaultSettings = deserializeJSON(fileRead(rootFolder & '.cfformat.json'));

        var isWindows = createObject('java', 'java.lang.System')
            .getProperty('os.name')
            .lcase()
            .contains('win');

        variables.executable = binFolder & 'cftokens' & (isWindows ? '.exe' : '_osx');
        defaultSettings['lf'] = isWindows ? chr(13) & chr(10) : chr(10);

        this.cfscript = new CFScript(this);
        this.cftags = new CFTags(this);
        this.cfscript.construct();
        this.cftags.construct();
        return this;
    }

    function mergedSettings(settings) {
        return duplicate(defaultSettings).append(settings);
    }

    function formatFile(fullFilePath, settings = {}) {
        var tokens = tokenizeFile(fullFilePath);
        return format(tokens, mergedSettings(settings));
    }

    function formatDirectory(
        fullSrcPath,
        fullTempPath,
        settings = {},
        any callback
    ) {
        tokenizeDirectory(fullSrcPath, fullTempPath);
        var fileArray = directoryList(fullSrcPath, true, 'path', '*.cfc');
        var fileMap = fileArray.reduce((r, f) => {
            r[f] = f.replace(fullSrcPath, fullTempPath).reReplace('.cfc$', '');
            return r;
        }, {});

        settings = mergedSettings(settings);

        while (!fileMap.isEmpty()) {
            fileMap.each(function(src, target) {
                var success = true;
                var message = '';

                if (fileExists(target & '.json')) {
                    var tokenJSON = fileRead(target & '.json');
                    if (!isJSON(tokenJSON)) {
                        // file exists, but hasn't had JSON written out to it yet
                        return;
                    }
                    var tokens = deserializeJSON(tokenJSON);
                    try {
                        var formatted = format(tokens, settings);
                        fileWrite(src, formatted, 'utf-8');
                    } catch (any e) {
                        success = false;
                        message = e.message;
                    }
                } else if (fileExists(target & '.error')) {
                    success = false;
                    message = fileRead(target & '.error');
                } else {
                    return;
                }

                fileMap.delete(src);
                if (!isNull(callback)) {
                    callback(
                        message.len() ? message : src,
                        success,
                        fileArray.len() - fileMap.count(),
                        fileArray.len()
                    );
                }
            });
        }

        directoryDelete(fullTempPath, true);
    }

    function formatFiles(
        paths,
        fullTempPath,
        settings,
        callback
    ) {
        directoryCreate(fullTempPath, true);

        var fullManifestPath = fullTempPath & 'manifest.txt';
        fileWrite(fullManifestPath, paths.toList(defaultSettings.lf), 'utf-8');
        tokenizeManifest(fullManifestPath);

        var fileMap = {};
        for (var path in paths) {
            var hashKey = hash(path, 'md5', 'utf-8').lcase();
            fileMap[path] = fullTempPath & hashKey;
        }

        while (!fileMap.isEmpty()) {
            fileMap.each(function(src, target) {
                var success = true;
                var message = '';

                if (fileExists(target & '.json')) {
                    var tokenJSON = fileRead(target & '.json');
                    if (!isJSON(tokenJSON)) {
                        // file exists, but hasn't had JSON written out to it yet
                        return;
                    }
                    var tokens = deserializeJSON(tokenJSON);
                    try {
                        var formatted = format(tokens, mergedSettings(settings[src]));
                        fileWrite(src, formatted, 'utf-8');
                    } catch (any e) {
                        success = false;
                        message = e.message;
                    }
                } else if (fileExists(target & '.error')) {
                    success = false;
                    message = fileRead(target & '.error');
                } else {
                    return;
                }

                fileMap.delete(src);
                if (!isNull(callback)) {
                    callback(
                        message.len() ? message : src,
                        success,
                        paths.len() - fileMap.count(),
                        paths.len()
                    );
                }
            });
        }

        directoryDelete(fullTempPath, true);
    }

    function cftokens(tokens) {
        return new CFTokens(tokens);
    }

    function format(tokens, settings) {
        var type = determineFileType(tokens);
        if (type == 'cftags') {
            tokens = postProcess(tokens);
        }
        var cftokens = cftokens(tokens.elements);
        return this[type].print(cftokens, settings);
    }

    function determineFileType(tokens) {
        for (var token in tokens.elements) {
            if (isArray(token) && token[2].find('source.cfml.script')) return 'cfscript';
            if (isStruct(token) && token.type.startswith('cftag')) return 'cftags';
        }
        return 'cftags';
    }

    function tokenizeFile(fullFilePath) {
        var tokens = '';
        cfexecute(name=executable arguments="""#fullFilePath#""" variable="tokens" timeout=10);
        if (!isJSON(tokens)) {
            throw(tokens);
        }
        return deserializeJSON(tokens);
    }

    function tokenizeDirectory(fullSrcPath, fullTempPath) {
        cfexecute(name=executable arguments="""#fullSrcPath#"" ""#fullTempPath#""");
    }

    function tokenizeManifest(fullManifestPath) {
        cfexecute(name=executable arguments="""#fullManifestPath#""");
    }

    function postProcess(tokens) {
        var stack = [{elements: [], tagName: ''}];
        for (var i = tokens.elements.len(); i > 0; i--) {
            var token = tokens.elements[i];

            if (
                isArray(token) ||
                (!token.type.startsWith('cftag') && !token.type.startsWith('htmltag'))
            ) {
                stack.last().elements.append(token);
                continue;
            }

            var tagName = token.elements[1][1];

            if (['cftag-closed', 'htmltag-closed'].find(token.type)) {
                var tag = {
                    tagName: tagName,
                    type: token.type.replace('-closed', '-body'),
                    endTag: token,
                    elements: []
                }
                stack.last().elements.append(tag);
                stack.append(tag);
            } else if (
                ['cftag', 'htmltag'].find(token.type) &&
                stack.last().tagName == tagName
            ) {
                stack.last().elements = stack.last().elements.reverse();
                stack.last().startTag = token;
                stack.deleteAt(stack.len());
            } else {
                token.tagName = tagName;
                stack.last().elements.append(token);
            }
        }

        stack.last().elements = stack.last().elements.reverse();
        return stack[1];
    }

    function indentTo(indent, settings) {
        if (settings.tab_indent) return repeatString(chr(9), indent);
        var numSpaces = settings.indent_size * indent;
        return repeatString(' ', numSpaces);
    }

    function indentToColumn(count, settings) {
        var indentCount = int(count / settings.indent_size);
        var numSpaces = count % settings.indent_size;
        return indentTo(indentCount, settings) & repeatString(' ', numSpaces);
    }

    function nextOffset(currentOffset, text, settings) {
        var tabSpaces = repeatString(' ', settings.indent_size);
        if (text.find(chr(10))) {
            var lastLine = reMatch('\n[^\n]*$', text)[1];
            return lastLine.replace(chr(9), tabSpaces, 'all').len();
        }

        return currentOffset + text.replace(chr(9), tabSpaces, 'all').len();
    }

    function calculateIndentSize(text, settings) {
        var tabSpaces = repeatString(' ', settings.indent_size);
        var normalizedTxt = text.replace(chr(9), tabSpaces, 'all');
        return normalizedTxt.len() - normalizedTxt.ltrim().len();
    }

}
