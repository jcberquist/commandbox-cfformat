component accessors="true" {

    function run() {
        syntect();
        cftokens();
    }

    function cftokens() {
        var dir = resolvePath('./cftokens/');
        command('!cargo build --release').inWorkingDirectory(dir).run();

        print.line('Copying binary to "./bin/" folder...');
        var cftokensVersion = deserializeJSON(fileRead(dir & '../box.json')).cftokens;
        var srcBinaryName = isWindows() ? 'cftokens.exe' : 'cftokens';
        var targetBinaryName = isWindows() ? 'cftokens.exe' : 'cftokens_osx';
        var src = resolvePath('./cftokens/target/release/#srcBinaryName#');
        var dest = resolvePath('./bin/#cftokensVersion#/');
        directoryCreate(dest, true, true);
        fileCopy(src, dest & targetBinaryName);

        if (!isWindows()) {
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

    function isWindows() {
        var osName = createObject('java', 'java.lang.System').getProperty('os.name').lcase();
        return osName.contains('win');
    }

}
