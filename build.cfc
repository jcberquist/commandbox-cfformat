component accessors="true" {

    property tempDir inject="tempDir@constants";
    property filesystem inject="filesystem";
    property JSONService inject="JSONService";

    function preTask() {
        variables.cftokens = new cftokens(wirebox);
    }

    function run() {
        examples();
        reference();
    }

    function testdata(string name) {
        var dir = resolvePath('./tests/data/');
        directoryCreate(dir & name);
        fileWrite(dir & name & '/formatted.txt', '');
        fileWrite(dir & name & '/settings.json', '[{}]');
        fileWrite(dir & name & '/source.cfc', '//' & chr(10));
    }

    function examples() {
        var dir = resolvePath('./');
        var binary = cftokens.getExecutable().find('_') ? 'cftokens' : 'cftokens.exe';
        var cftokensVersion = deserializeJSON(fileRead(dir & 'box.json')).cftokens;
        var reference = deserializeJSON(fileRead(dir & 'data/reference.json'));
        var refDir = tempDir & '/' & createUUID() & '/';
        var codeDir = refDir & 'examples/';
        var tokensDir = refDir & 'tokens/';

        directoryCreate(codeDir, true, true);

        for (var setting in reference) {
            if (reference[setting].keyExists('example')) {
                var startString = '//' & chr(10);
                if (reFindNoCase('^\s*<[a-z]+', reference[setting].example.code)) {
                    startString = '';
                }
                fileWrite(codeDir & setting & '.cfc', startString & reference[setting].example.code);
            }
        }

        // generate token json files
        cfexecute(
            name = expandPath(dir & "bin/#cftokensVersion#/#binary#"),
            arguments = "parse ""#codeDir#"" ""#tokensDir#""",
            timeout = 10
        );

        // generate examples
        var cfformat = new models.CFFormat('', dir);
        var examples = structNew('ordered');
        for (var setting in reference) {
            if (reference[setting].keyExists('example')) {
                var output = structNew('ordered');
                var values = reference[setting].example.keyExists('values') ? reference[setting].example.values : [];
                if (reference[setting].keyExists('values')) {
                    values = reference[setting].values;
                } else if (reference[setting].type == 'boolean') {
                    values = [true, false];
                }

                for (var v in values) {
                    reference[setting].example.settings[setting] = v;
                    var tokens = deserializeJSON(fileRead(tokensDir & setting & '.json'));
                    var formatted = cfformat.format(
                        tokens,
                        cfformat.mergedSettings(reference[setting].example.settings)
                    );
                    output[v] = formatted
                        .replace(chr(13), '', 'all')
                        .reReplace('//[ ]?', '// #setting#: #isNull(v) ? 'null' : serializeJSON(v)#')
                        .trim();
                }

                examples[setting] = output;
            }
        }

        JSONService.writeJSONFile(dir & 'data/examples.json', examples);
    }

    function reference() {
        var dir = resolvePath('./');

        var lf = filesystem.isWindows() ? chr(13) & chr(10) : chr(10);
        var defaultSettings = deserializeJSON(fileRead(dir & '.cfformat.json'));
        var reference = deserializeJSON(fileRead(dir & 'data/reference.json'));
        var examples = deserializeJSON(fileRead(dir & 'data/examples.json'));
        var markdown = ['## Settings Reference'];

        for (var setting in reference) {
            var md = '#### ' & setting & lf;

            if (reference[setting].type != 'struct-key-value') {
                md &= lf & 'Type: _#reference[setting].type#_' & lf;
            }

            if (reference[setting].type == 'string') {
                var md_values = reference[setting].values
                    .map((v) => {
                        return defaultSettings[setting] == v ? '**#serializeJSON(v)#**' : serializeJSON(v);
                    })
                    .toList(', ');
                md &= lf & 'Values: [#md_values#]' & lf;
            } else {
                md &= lf & 'Default: **#serializeJSON(defaultSettings[setting])#**' & lf;
            }

            if (reference[setting].description.len()) {
                md &= lf & reference[setting].description & lf;
            }
            if (examples.keyExists(setting)) {
                md &= lf & '```cfc' & lf & structValueArray(examples[setting]).toList(lf & lf) & lf & '```';
            }
            markdown.append(md);
        }

        fileWrite(dir & 'reference.md', markdown.toList(lf & lf), 'utf-8');
    }

    function cftokens() {
        var dir = resolvePath('./');
        var cftokensVersion = deserializeJSON(fileRead(dir & 'box.json')).cftokens;
        var binFolder = dir & 'bin/#cftokensVersion#/';
        var executable = cftokens.getExecutable();
        var executableName = executable.find('_') ? 'cftokens' : 'cftokens.exe';
        var downloadURL = 'https://github.com/jcberquist/cftokens/releases/download/#cftokensVersion#/';

        cftokens.ensureExecutableExists(
            binFolder & executableName,
            downloadURL & executable
        );
    }

    function tokens(string path) {
        var dir = resolvePath('./');
        var binary = cftokens.getExecutable().find('_') ? 'cftokens' : 'cftokens.exe';
        var cftokensVersion = deserializeJSON(fileRead(dir & 'box.json')).cftokens;

        // generate tokens
        var tokenjson = '';
        cfexecute(
            name = expandPath(dir & "bin/#cftokensVersion#/#binary#"),
            arguments = "parse ""#resolvePath(path)#""",
            variable = "tokenjson",
            timeout = 10
        );

        print.line(deserializeJSON(tokenjson));
    }

    private function structValueArray(required struct structure) {
        return arguments.structure.reduce((values, _, value) => {
            values.append(value);
            return values;
        }, []);
    }

}
