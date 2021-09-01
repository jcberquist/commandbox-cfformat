component {

    this.cfmapping = 'cfformat';
    this.autoMapModels = false;

    function configure() {
        settings = {
            downloadURL: 'https://github.com/jcberquist/cftokens/releases/download/{version}/',
            executable: ''
        };
    }

    function onLoad() {
        var cftokens = new cftokens(wirebox);
        var fullModulePath = modulePath.replace('\', '/', 'all') & (modulePath.endswith('/') ? '' : '/');
        var cftokensVersion = deserializeJSON(fileRead(fullModulePath & 'box.json')).cftokens;
        var binFolder = fullModulePath & 'bin/#cftokensVersion#/';
        var executable = settings.executable.len() ? settings.executable : cftokens.getExecutable();
        var executableName = executable.find('_') ? 'cftokens' : 'cftokens.exe';

        cftokens.ensureExecutableExists(
            binFolder & executableName,
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

}
