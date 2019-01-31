component {

    this.autoMapModels = false;

    function configure() {
        settings = {downloadURL: 'https://github.com/jcberquist/commandbox-cfformat/releases/download/{version}/'};
    }

    function onLoad() {
        var fullModulePath = modulePath.replace('\', '/', 'all') & (modulePath.endswith('/') ? '' : '/');
        var cftokensVersion = deserializeJSON(fileRead(fullModulePath & 'box.json')).cftokens;
        var binFolder = fullModulePath & 'bin/#cftokensVersion#/';
        var dataFolder = fullModulePath & 'data/';
        var executable = wirebox.getInstance('filesystem').isWindows() ? 'cftokens.exe' : 'cftokens_osx';

        binder
            .map('cfformat@commandbox-cfformat')
            .to('#moduleMapping#.models.CFFormat')
            .asSingleton()
            .initWith(binFolder, dataFolder);

        ensureExecutableExists(
            binFolder & executable,
            settings.downloadURL.replace('{version}', cftokensVersion) & executable
        );
    }

    function ensureExecutableExists(executablePath, downloadURL) {
        if (fileExists(executablePath)) return;

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
            job.addLog(
                'Alternatively if you have Rust installed on your machine you can compile the executable yourself by running the `build.cfc` task in the root of this module.'
            );

            // Remove any partial download.
            if (fileExists(executablePath)) {
                fileDelete(executablePath);
            }
            job.error(dumplog = true);
        }
    }

}
