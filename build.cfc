component accessors="true" {

    property tempDir inject="tempDir@constants";
    property filesystem inject="filesystem";

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
        var targetBinaryName = filesystem.isWindows() ? 'cftokens.exe' : 'cftokens_osx';
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
        } else {
            print.line('Pulling sublimehq Packages repo from GitHub...').toConsole();
            command('!git pull').inWorkingDirectory(cftokensLibDir & 'Packages').run();
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

    function reference() {
        var dir = resolvePath('./');

        var binary = filesystem.isWindows() ? 'cftokens.exe' : 'cftokens_osx';
        var lf = filesystem.isWindows() ? chr(13) & chr(10) : chr(10);
        var cftokensVersion = deserializeJSON(fileRead(dir & 'box.json')).cftokens;
        var defaultSettings = deserializeJSON(fileRead(dir & '.cfformat.json'));
        var validSettings = deserializeJSON(fileRead(dir & 'data/validSettings.json'));
        var reference = deserializeJSON(fileRead(dir & 'data/reference.json'));
        var refDir = tempDir & '/' & createUUID() & '/';
        var codeDir = refDir & 'samples/';
        var tokensDir = refDir & 'tokens/';

        directoryCreate(codeDir, true, true);

        for (var setting in reference) {
            if (reference[setting].keyExists('code')) {
                fileWrite(codeDir & setting & '.cfc', '//' & chr(10) & reference[setting].code);
            }
        }

        // generate token json files
        cfexecute(
            name=expandPath(dir & "bin/#cftokensVersion#/#binary#")
            arguments="""#codeDir#"" ""#tokensDir#"""
            timeout=10
        );

        // generate formatting samples
        var cfformat = new models.CFFormat('', dir);
        for (var setting in reference) {
            if (reference[setting].keyExists('code')) {
                var samples = [];
                var values = reference[setting].keyExists('sample_values') ? reference[setting].sample_values : [];
                if (validSettings[setting].keyExists('values')) {
                    values = validSettings[setting].values;
                } else if (validSettings[setting].type == 'boolean') {
                    values = [true, false];
                }

                for (var v in values) {
                    reference[setting].settings[setting] = isNull(v) ? nullValue() : v;
                    var tokens = deserializeJSON(fileRead(tokensDir & setting & '.json'));
                    var formatted = cfformat.format(tokens, cfformat.mergedSettings(reference[setting].settings));
                    samples.append(
                        formatted.reReplace('//\s?', '// #setting#: #isNull(v) ? 'null' : serializeJSON(v)#')
                    );
                }

                reference[setting].code = samples.toList(lf & lf);
            }
        }

        directoryDelete(refDir, true);

        var markdown = ['## Settings Reference'];

        for (var setting in reference) {
            var md = '#### ' & setting & lf;

            if (validSettings[setting].type != 'struct-key-value') {
                md &= lf & 'Type: _#validSettings[setting].type#_' & lf;
            }

            if (validSettings[setting].type == 'string') {
                var md_values = validSettings[setting].values
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
            if (reference[setting].keyExists('code')) {
                md &= lf & '```cfc' & lf & reference[setting].code & lf & '```';
            }
            markdown.append(md);
        }

        fileWrite(dir & 'reference.md', markdown.toList(lf & lf), 'utf-8');
    }

}
