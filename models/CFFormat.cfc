component accessors="true" {

    property rootFolder;
    property defaultSettings;
    property reference;
    property examples;
    property executable;

    function init(required string binFolder, required string rootFolder) {
        variables.rootFolder = arguments.rootFolder;
        variables.defaultSettings = deserializeJSON(fileRead(rootFolder & '.cfformat.json'));
        variables.reference = deserializeJSON(fileRead(rootFolder & 'data/reference.json'));
        variables.examples = deserializeJSON(fileRead(rootFolder & 'data/examples.json'));
        variables.platform = getPlatform();
        variables.lf = platform == 'windows' ? chr(13) & chr(10) : chr(10);

        variables.executable = binFolder & 'cftokens' & (platform == 'windows' ? '.exe' : '_#platform#');

        this.cfscript = new CFScript(this);
        this.cftags = new CFTags(this);
        this.delimited = new Delimited(this);
        this.alignment = new Alignment();
        this.cfscript.construct();
        this.cftags.construct();
        return this;
    }

    function mergedSettings(userSettings, internal = true) {
        var merged = duplicate(defaultSettings);

        var validationError = function(message) {
            throw(type = 'CFFormat.settings.validation', message = message);
        }

        for (var key in userSettings) {
            if (!reference.keyExists(key)) {
                validationError('[#key#] is not a valid setting name.');
            }

            var setting = reference[key];
            var invalidSetting = 'Setting [#key#] to [#userSettings[key]#] is not valid. ';

            switch (setting.type) {
                case 'boolean':
                    if (![true, false].find(userSettings[key])) {
                        validationError(invalidSetting & 'Valid options are [true,false].');
                    }
                    break;
                case 'string':
                    if (!setting.values.find(userSettings[key])) {
                        validationError(invalidSetting & 'Valid options are #serializeJSON(setting.values)#.');
                    }
                    break;
                case 'integer':
                    if (!isValid('integer', userSettings[key]) || userSettings[key] < 0) {
                        validationError(invalidSetting & '[#key#] must be a positive integer.');
                    }
                    break;
                case 'struct-key-value':
                    if (![':', '='].find(userSettings[key].trim()) || userSettings[key].len() > 3) {
                        validationError(
                            invalidSetting & '[#key#] must contain either a single `:` or `=` and be no more than 3 characters in length.'
                        );
                    }
                    break;
            }
            merged[key] = userSettings[key];
        }

        // internally we use `lf` not `newline`
        if (internal) {
            merged.lf = merged.newline == 'os' ? variables.lf : merged.newline;
        }

        return merged;
    }

    function formatFile(fullFilePath, settings = {}) {
        var tokens = cftokensFile('parse', fullFilePath);
        return format(tokens, mergedSettings(settings));
    }

    function formatDirectory(
        fullSrcPath,
        fullTempPath,
        settings = {},
        callback,
        cfm
    ) {
        cftokensDirectory('parse', fullSrcPath, fullTempPath);
        var filter = cfm ? '*.cfc|*.cfm' : '*.cfc';
        var fileArray = directoryList(fullSrcPath, true, 'path', filter);
        var settingsMap = {};
        var fileMap = {};
        for (var path in fileArray) {
            fileMap[path] = path.replace(fullSrcPath, fullTempPath).left(-4);
            settingsMap[path] = settings;
        }

        formatFileMap(fileMap, settingsMap, callback);
        directoryDelete(fullTempPath, true);
    }

    function formatFiles(
        paths,
        fullTempPath,
        settingsMap,
        callback
    ) {
        directoryCreate(fullTempPath, true);

        var fullManifestPath = fullTempPath & 'manifest.txt';
        fileWrite(fullManifestPath, paths.toList(variables.lf), 'utf-8');
        cftokensManifest('parse', fullManifestPath);

        var fileMap = {};
        for (var path in paths) {
            var hashKey = hash(path, 'md5', 'utf-8').lcase();
            fileMap[path] = fullTempPath & hashKey;
        }

        formatFileMap(fileMap, settingsMap, callback);
        directoryDelete(fullTempPath, true);
    }

    function formatFileMap(fileMap, settingsMap, callback) {
        var fileCount = fileMap.count();
        while (!fileMap.isEmpty()) {
            fileMap.each(function(src, target) {
                var success = true;
                var message = '';
                var formatted = '';

                if (fileExists(target & '.json')) {
                    var tokenJSON = fileRead(target & '.json');
                    if (!isJSON(tokenJSON)) {
                        // file exists, but hasn't had JSON written out to it yet
                        return;
                    }
                    var tokens = deserializeJSON(tokenJSON);
                    try {
                        formatted = format(tokens, mergedSettings(settingsMap[src]));
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
                callback(
                    src,
                    formatted,
                    success,
                    message,
                    fileCount - fileMap.count(),
                    fileCount
                );
            });
        }
    }

    function cftokens(tokens) {
        return new CFTokens(tokens);
    }

    function format(tokens, settings) {
        var bom = '';

        if (arrayLen(tokens.elements)) {
            if (
                isArray(tokens.elements[1]) &&
                arrayLen(tokens.elements[1][2]) &&
                tokens.elements[1][2][1] == 'bom'
            ) {
                bom = tokens.elements[1][1];
                arrayDeleteAt(tokens.elements, 1);
            }

            while (isArray(tokens.elements[1]) && arrayLen(tokens.elements[1][2]) == 0) {
                arrayDeleteAt(tokens.elements, 1);
            }
        }

        var type = determineFileType(tokens);
        if (type == 'cftags') {
            tokens = postProcess(tokens);
        }
        var cftokens = cftokens(tokens.elements);
        var formatted = this[type].print(cftokens, settings);

        // alignment
        if (settings['alignment.consecutive.assignments']) {
            formatted = this.alignment.alignAssignments(formatted);
        }
        if (settings['alignment.consecutive.properties']) {
            formatted = this.alignment.alignAttributes(formatted, 'properties');
        }
        if (settings['alignment.consecutive.params']) {
            formatted = this.alignment.alignAttributes(formatted, 'params');
        }

        return bom & formatted;
    }

    function determineFileType(tokens) {
        for (var token in tokens.elements) {
            if (isArray(token) && token[2].find('source.cfml.script')) return 'cfscript';
            if (isStruct(token) && token.type.startswith('cftag')) return 'cftags';
        }
        return 'cftags';
    }

    function cftokensFile(cmd, fullFilePath) {
        var tokens = '';
        cfexecute(
            name=executable,
            arguments="#cmd# ""#fullFilePath#""",
            variable="tokens",
            timeout=10
        );
        if (!isJSON(tokens)) {
            throw(tokens);
        }
        return deserializeJSON(tokens);
    }

    function cftokensDirectory(cmd, fullSrcPath, fullTempPath) {
        var devnull = createObject('java', 'java.io.File').init(getPlatform() == 'windows' ? 'NUL' : '/dev/null');
        var p = createObject('java', 'java.lang.ProcessBuilder')
            .init([executable, cmd, fullSrcPath, fullTempPath])
            .redirectErrorStream(true)
            .redirectOutput(devnull)
            .start();
    }

    function cftokensManifest(cmd, fullManifestPath) {
        var devnull = createObject('java', 'java.io.File').init(getPlatform() == 'windows' ? 'NUL' : '/dev/null');
        var p = createObject('java', 'java.lang.ProcessBuilder')
            .init([executable, cmd, fullManifestPath])
            .redirectErrorStream(true)
            .redirectOutput(devnull)
            .start();
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

        // verify that all tags were matched before continuing
        if (stack.len() > 1) {
            throw('Unbalanced closing tag found - &lt;/#stack.last().tagname#&gt;.')
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
            var lastLine = reMatch('\n[^\n]*$', text).last();
            return lastLine.replace(chr(9), tabSpaces, 'all').len() - 1;
        }

        return currentOffset + text.replace(chr(9), tabSpaces, 'all').len();
    }

    function calculateIndentSize(text, settings) {
        var tabSpaces = repeatString(' ', settings.indent_size);
        var normalizedTxt = text.replace(chr(9), tabSpaces, 'all');
        return normalizedTxt.len() - normalizedTxt.ltrim().len();
    }

    function getPlatform() {
        var osName = createObject('java', 'java.lang.System').getProperty('os.name').lcase();
        if (osName.contains('win')) return 'windows';
        if (osName.contains('linux')) return 'linux';
        if (osName.contains('mac')) return 'osx';
    }

}
