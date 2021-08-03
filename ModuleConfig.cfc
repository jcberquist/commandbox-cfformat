component {

    this.cfmapping = 'cfformat';
    this.autoMapModels = false;

    function configure() {
        settings = {
            downloadURL: 'https://github.com/jcberquist/cftokens/releases/download/{version}/',
            executable: getExecutable()
        };
    }

    function onLoad() {
        var fullModulePath = modulePath.replace('\', '/', 'all') & (modulePath.endswith('/') ? '' : '/');
        var cftokensVersion = deserializeJSON(fileRead(fullModulePath & 'box.json')).cftokens;
        var binFolder = fullModulePath & 'bin/#cftokensVersion#/';
        var executableName = settings.executable.find('_') ? 'cftokens' : 'cftokens.exe';

        ensureExecutableExists(
            binFolder & executableName,
            settings.downloadURL.replace('{version}', cftokensVersion) & settings.executable
        );

        binder
            .map('cfformatutils@commandbox-cfformat')
            .to('#moduleMapping#.models.CFFormatUtils')
            .asSingleton();

        binder
            .map('cfformat@commandbox-cfformat')
            .to('#moduleMapping#.models.CFFormat')
            .asSingleton()
            .initWith(binFolder, fullModulePath);
    }

    function ensureExecutableExists(executablePath, downloadURL) {
        if (fileExists(executablePath)) return;

        directoryCreate(getDirectoryFromPath(executablePath), true, true);

        var job = wirebox.getInstance('InteractiveJob');
        job.start('cftokens executable not found.  Please wait for a moment while it is downloaded.');

        job.addLog('Downloading [#downloadURL#]');

        var progressableDownloader = wirebox.getInstance(dsl = 'ProgressableDownloader');
        var progressBar = wirebox.getInstance(dsl = 'ProgressBar');

        try {
            progressableDownloader.download(
                downloadURL,
                executablePath,
                function(status) {
                    progressBar.update(argumentCollection = status);
                }
            );
            job.complete();
        } catch (any var e) {
            job.addErrorLog('Unable to download the executable:');
            job.addErrorLog('#e.message##chr(10)##e.detail#');
            job.addLog('Please manually place the file here:');
            job.addLog(executablePath);

            // Remove any partial download.
            if (fileExists(executablePath)) {
                fileDelete(executablePath);
            }
            job.error(dumplog = true);
        }

        if (!wirebox.getInstance('filesystem').isWindows()) {
            cfexecute(name = "chmod +x ""#executablePath#""", timeout = 10);
        }
    }

    function getExecutable() {
        var fs = wirebox.getInstance('filesystem');
        if (fs.isWindows()) return 'cftokens.exe';
        if (fs.isMac()) return 'cftokens_osx';
        if (fs.isLinux()) {
            // try to detect whether we are on a system using musl
            // note ldd --version outputs to stderr
            var p = createObject('java', 'java.lang.ProcessBuilder')
                .init(['ldd', '--version'])
                .redirectErrorStream(true)
                .start();
            var inputStreamReader = createObject('java', 'java.io.InputStreamReader').init(p.getInputStream(), 'utf-8');
            var bufferedReader = createObject('java', 'java.io.BufferedReader').init(inputStreamReader);
            var collector = createObject('java', 'java.util.stream.Collectors').joining(chr(10));
            var output = bufferedReader.lines().collect(collector);
            return output.findNoCase('musl') ? 'cftokens_linux_musl' : 'cftokens_linux';
        }
    }

}
