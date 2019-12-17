component accessors=true {

    property name="beanFactory" inject="wirebox";
    property name="shell" inject="shell";
    property name="filesystemUtil" inject="FileSystem";
    property name="ConfigService" inject="ConfigService";

    function resolvePath(required string path, basePath = shell.pwd()) {
        return filesystemUtil.resolvepath(path, basePath);
    }

    function globber(pattern = '') {
        var globber = beanFactory.getInstance('Globber');
        if (pattern.len()) {
            globber.setPattern(arguments.pattern);
        }
        return globber;
    }

    function resolveFormatPath(path) {
        var fullPath = resolvePath(path);

        var pathType = 'glob';
        if (directoryExists(fullPath)) {
            pathType = 'dir';
        } else if (fileExists(fullPath)) {
            pathType = 'file';
            if (!fullPath.endsWith('.cfc')) {
                return [];
            }
        }

        return {pathType: pathType, filePaths: resolveFilePaths(fullPath, pathType)};
    }

    function resolveFilePaths(fullPath, pathType) {
        if (pathType == 'file') return [fullPath];

        if (pathType == 'dir') {
            var pathGlobs = [fullPath & '**.cfc'];
        } else {
            var pathGlobs = fullPath
                .listToArray(chr(10) & ',')
                .map((p) => {
                    var glob = resolvePath(p.trim());
                    if (directoryExists(glob)) glob &= '**.cfc';
                    return glob;
                });
        }

        var paths = [];
        pathGlobs.each((g) => {
            globber(g)
                .matches()
                .each((m) => {
                    if (m.lcase().endswith('.cfc') && !paths.find(m)) {
                        paths.append(m);
                    }
                })
        });
        return paths;
    }

    function resolveSettings(paths, inlineSettingsPath) {
        var settings = {
            config: {},
            inline: {},
            sources: {},
            paths: {}
        };

        // CommandBox config settings
        var configPath = resolvePath(configService.getSetting('cfformat.settings', '~/.cfformat.json'));
        if (fileExists(configPath)) {
            settings.config = {path: configPath, settings: deserializeJSON(fileRead(configPath))};
        }

        // inline settings
        if (inlineSettingsPath.len()) {
            inlineSettingsPath = resolvePath(inlineSettingsPath);
            if (!fileExists(inlineSettingsPath)) {
                throw(inlineSettingsPath & ' is not a valid path.');
            }
            settings.inline = {path: inlineSettingsPath, settings: deserializeJSON(fileRead(inlineSettingsPath))};
        }

        // per path settings
        var settingsCache = {dirs: {}, settings: {}}
        for (var path in paths) {
            settings.paths[path] = {};
            settings.sources[path] = [];

            if (!settings.config.isEmpty()) {
                settings.paths[path].append(settings.config.settings);
                settings.sources[path].append(settings.config.path);
            }

            var formatDir = getDirectoryFromPath(path).replace('\', '/', 'all');
            var pathSettings = findSettings(formatDir, settingsCache);
            if (!pathSettings.isEmpty()) {
                settings.paths[path].append(pathSettings.settings);
                settings.sources[path].append(pathSettings.path);
            }

            if (!settings.inline.isEmpty()) {
                settings.paths[path].append(settings.inline.settings);
                settings.sources[path].append(settings.inline.path);
            }
        }

        return settings;
    }

    function findSettings(formatDir, settingsCache = {dirs: {}, settings: {}}) {
        var dirsChecked = [];

        while (formatDir.listLen('/') > 0) {
            var fullPath = formatDir & '.cfformat.json';
            dirsChecked.append(formatDir);

            if (settingsCache.dirs.keyExists(formatDir)) {
                var settingsPath = settingsCache.dirs[formatDir];
                dirsChecked.each((d) => settingsCache.dirs[d] = settingsPath);
                if (!settingsPath.len()) return {};
                return {path: settingsPath, settings: settingsCache.settings[settingsPath]}
            }

            if (fileExists(fullPath)) {
                settingsCache.settings[fullPath] = deserializeJSON(fileRead(fullPath));
                dirsChecked.each((d) => settingsCache.dirs[d] = fullPath);
                return {path: fullPath, settings: settingsCache.settings[fullPath]}
            }

            if (directoryExists(formatDir & '/.git/')) {
                break;
            }

            formatDir = formatDir.listDeleteAt(formatDir.listLen('/'), '/') & '/';
        }

        // didn't find any settings, note this in the cache
        dirsChecked.each((d) => settingsCache.dirs[d] = '');
        return {};
    }

}
