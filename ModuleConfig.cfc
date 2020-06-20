component {

    this.cfmapping = 'cfformat';
    this.autoMapModels = false;

    function configure() {
        settings = {downloadURL: 'https://github.com/jcberquist/cftokens/releases/download/{version}/'};
    }

    function onLoad() {
        var fullModulePath = modulePath.replace('\', '/', 'all') & (modulePath.endswith('/') ? '' : '/');
        var cftokensVersion = deserializeJSON(fileRead(fullModulePath & 'box.json')).cftokens;
        var binFolder = fullModulePath & 'bin/#cftokensVersion#/';
        var executable = getExecutableName();

        ensureExecutableExists(
            binFolder & executable,
            settings.downloadURL.replace('{version}', cftokensVersion) & executable
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
        job.start(
            'cftokens executable [#executablePath.listLast('/')#] not found.  Please wait for a moment while it is downloaded.'
        );

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

    function getExecutableName() {
        var fs = wirebox.getInstance('filesystem');
        if (fs.isWindows()) return 'cftokens.exe';
        if (fs.isMac()) return 'cftokens_osx';
        if (fs.isLinux()) return 'cftokens_linux';
    }

}
