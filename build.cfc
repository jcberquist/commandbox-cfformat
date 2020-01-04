component accessors="true" {

    property tempDir inject="tempDir@constants";
    property filesystem inject="filesystem";
    property JSONService inject="JSONService";
	property JSONPrettyPrint inject="provider:JSONPrettyPrint";


    function run() {
        syntect();
        cftokens();
    }

    function cftokens() {
        var dir = resolvePath('./cftokens/');
        command('!cargo build --release').inWorkingDirectory(dir).run();

        print.line('Copying binary to "./bin/" folder...');
        var cftokensVersion = deserializeJSON(fileRead(dir & '../box.json')).cftokens;
        var srcBinaryName = filesystem.isWindows() ? 'cftokens.exe' : 'cftokens';
        var targetBinaryName = getTargetBinaryName();
        var src = resolvePath('./cftokens/target/release/#srcBinaryName#');
        var dest = resolvePath('./bin/#cftokensVersion#/');
        directoryCreate(dest, true, true);
        fileCopy(src, dest & targetBinaryName);

        if (!filesystem.isWindows()) {
            print.line('Ensuring that it is executable...');
            command('!chmod +x "#dest & targetBinaryName#"').run();
        }

        print.text('Binary is at: ');
        print.greenLine(dest & targetBinaryName);
    }

    function syntect() {
        var cftokensLibDir = resolvePath('./cftokens/lib/');

        if (!directoryExists(cftokensLibDir & 'syntect')) {
            print.line('Cloning Syntect repo from GitHub...').toConsole();
            command('!git clone https://github.com/trishume/syntect.git ./syntect').inWorkingDirectory(cftokensLibDir).run();
        } else {
            print.line('Pulling Syntect repo from GitHub...').toConsole();
            command('!git pull').inWorkingDirectory(cftokensLibDir & 'syntect').run();
        }

        print.line('Cleaning testdata folder...')
        directoryDelete(cftokensLibDir & 'syntect/testdata', true);
        directoryCreate(cftokensLibDir & 'syntect/testdata');

        if (!directoryExists(cftokensLibDir & 'Packages')) {
            print.line('Cloning sublimehq Packages repo from GitHub...').toConsole();
            command('!git clone https://github.com/sublimehq/Packages.git ./Packages')
                .inWorkingDirectory(cftokensLibDir)
                .run();
            command('!git checkout st3').inWorkingDirectory(cftokensLibDir & 'Packages').run();
        } else {
            print.line('Pulling sublimehq Packages repo from GitHub...').toConsole();
            command('!git fetch').inWorkingDirectory(cftokensLibDir & 'Packages').run();
            command('!git checkout st3').inWorkingDirectory(cftokensLibDir & 'Packages').run();
            command('!git merge FETCH_HEAD').inWorkingDirectory(cftokensLibDir & 'Packages').run();
        }

        if (!directoryExists(cftokensLibDir & 'CFML')) {
            print.line('Cloning CFML repo from GitHub...').toConsole();
            command('!git clone https://github.com/jcberquist/sublimetext-cfml.git ./CFML')
                .inWorkingDirectory(cftokensLibDir)
                .run();
        } else {
            print.line('Pulling CFML repo from GitHub...').toConsole();
            command('!git pull').inWorkingDirectory(cftokensLibDir & 'CFML').run();
        }

        print.line('Copyinging syntaxes...');
        for (var syntax in ['HTML', 'JavaScript', 'SQL', 'CSS']) {
            print.line('Copying ' & syntax & '...').toConsole();
            directoryCopy(
                cftokensLibDir & 'Packages/' & syntax,
                cftokensLibDir & 'syntect/testdata/' & syntax,
                false,
                '*.sublime-syntax'
            );
        }

        print.line('Copying CFML...').toConsole();
        directoryCopy(
            cftokensLibDir & 'CFML/syntaxes/',
            cftokensLibDir & 'syntect/testdata/CFML',
            false,
            (p) => p.contains('cfml') || p.contains('cfscript')
        );

        print.line('Adding UTF-8 BOM check to CFML syntax...').toConsole();

        var lf = filesystem.isWindows() ? chr(13) & chr(10) : chr(10);
        var syntaxPath = cftokensLibDir & 'syntect/testdata/CFML/cfml.sublime-syntax';
        syntax = fileRead(syntaxPath, 'utf-8');
        syntax = syntax.replace('match: (?i)(?=^', 'match: ^\xef\xbb\xbf#lf#      scope: bom#lf#    - match: (?i)(?=');
        fileWrite(syntaxPath, syntax, 'utf-8');

        var syntaxPath = cftokensLibDir & 'syntect/testdata/CFML/cfscript.sublime-syntax';
        syntax = fileRead(syntaxPath, 'utf-8');
        syntax = syntax.replace(
            'match: (?i)^\s*(?:(abstract|final)',
            'match: (?i)^(?:\xef\xbb\xbf)?\s*(?:(abstract|final)'
        );
        fileWrite(syntaxPath, syntax, 'utf-8');

        print.line('Adding CFFormat ignore scopes to CFML syntax...').toConsole();

        var scopes = fileRead(resolvePath('./data/ignoreScopes.txt')).listToArray('~');
        var lf = filesystem.isWindows() ? chr(13) & chr(10) : chr(10);
        var syntaxPath = cftokensLibDir & 'syntect/testdata/CFML/cfml.sublime-syntax';
        syntax = fileRead(syntaxPath, 'utf-8');
        syntax = syntax.replace('  comments:', '  comments:' & lf & scopes[1]);
        fileWrite(syntaxPath, syntax, 'utf-8');

        for (var fn in ['cfscript', 'cfscript-in-tags']) {
            var syntaxPath = cftokensLibDir & 'syntect/testdata/CFML/#fn#.sublime-syntax';
            syntax = fileRead(syntaxPath, 'utf-8');
            syntax = syntax.replace('  comments:', '  comments:' & lf & scopes[2].rtrim());
            fileWrite(syntaxPath, syntax, 'utf-8');
        }

        print.line();
        print.line('Building syntect packs...').toConsole();
        command(
            '!cargo run --features=metadata --example gendata -- synpack testdata assets/default_newlines.packdump assets/default_nonewlines.packdump assets/default_metadata.packdump'
        ).inWorkingDirectory(cftokensLibDir & 'syntect/').run();
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

        var binary = getTargetBinaryName();
        var lf = chr(10);
        var cftokensVersion = deserializeJSON(fileRead(dir & 'box.json')).cftokens;
        var reference = deserializeJSON(fileRead(dir & 'data/reference.json'));
        var refDir = tempDir & '/' & createUUID() & '/';
        var codeDir = refDir & 'examples/';
        var tokensDir = refDir & 'tokens/';

        directoryCreate(codeDir, true, true);

        for (var setting in reference) {
            if (reference[setting].keyExists('example')) {
                fileWrite(codeDir & setting & '.cfc', '//' & chr(10) & reference[setting].example.code);
            }
        }

        // generate token json files
        cfexecute(
            name=expandPath(dir & "bin/#cftokensVersion#/#binary#"),
            arguments="""#codeDir#"" ""#tokensDir#""",
            timeout=10
        );

        // generate examples
        var cfformat = new models.CFFormat('', dir);
        var examples = structNew( "ordered" );
        for (var setting in reference) {
            if (reference[setting].keyExists('example')) {
                var output = structNew( "ordered" );
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
                    output[ v ] = formatted
                        .replace(chr(13), '', 'all')
                        .reReplace('//\s?', '// #setting#: #isNull(v) ? 'null' : serializeJSON(v)#')
                        .trim();
                }

                examples[setting] = output;
            }
        }

        fileWrite(
            dir & 'data/examples.json',
            JSONPrettyPrint.formatJSON( examples )
        );
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
                md &= lf & '```cfc' & lf & structValueArray( examples[setting] ).toList(lf & lf) & lf & '```';
            }
            markdown.append(md);
        }

        fileWrite(dir & 'reference.md', markdown.toList(lf & lf), 'utf-8');
    }

    function tokens(string path) {
        var dir = resolvePath('./');
        var binary = getTargetBinaryName();
        var lf = filesystem.isWindows() ? chr(13) & chr(10) : chr(10);
        var cftokensVersion = deserializeJSON(fileRead(dir & 'box.json')).cftokens;

        // generate tokens
        var tokenjson = '';
        cfexecute(
            name=expandPath(dir & "bin/#cftokensVersion#/#binary#"),
            arguments="""#resolvePath(path)#""",
            variable="tokenjson",
            timeout=10
        );

        print.line(deserializeJSON(tokenjson));
    }

    function getTargetBinaryName() {
        if (filesystem.isWindows()) return 'cftokens.exe';
        if (filesystem.isMac()) return 'cftokens_osx';
        if (filesystem.isLinux()) return 'cftokens_linux';
    }

    private function structValueArray( required struct structure ) {
        return arguments.structure.reduce( ( values, _, value ) => {
            values.append( value );
            return values;
        }, [] );
    }

}
