component accessors="true" {

    variables.bifScope = 'meta.function-call.support.cfml support.function.cfml';
    variables.functionCallScope = 'meta.function-call.cfml variable.function.cfml';
    variables.functionNameScope = 'entity.name.function.cfml';
    variables.functionScope = 'variable.function.cfml';
    variables.methodCallScope = 'meta.function-call.method.cfml variable.function.cfml';
    variables.methodScope = 'meta.class.body.cfml meta.function.declaration.cfml entity.name.function.cfml';
    variables.scriptPropertyNameScope = 'meta.tag.property.name.cfml';
    variables.scriptPropertyScope = 'meta.tag.property.cfml entity.name.tag.script.cfml';
    variables.scriptTagScope = 'entity.name.tag.script.cfml';
    variables.tagMethodScopeRegex = 'meta.class.body.tag.cfml meta.tag.cfml meta.function.cfml.*entity.name.function.cfml$';
    variables.tagScope = 'entity.name.tag.cfml';

    function init(required any cfformat, required string lf) {
        variables.cfformat = arguments.cfformat;
        variables.lf = arguments.lf;
        return this;
    }

    function singleFileStats(fullFilePath) {
        var tokens = cfformat.cftokensFile('tokenize', fullFilePath);
        return stats(tokens);
    }

    function fileStats(paths, fullTempPath, callback) {
        directoryCreate(fullTempPath, true);

        var fullManifestPath = fullTempPath & 'manifest.txt';
        fileWrite(fullManifestPath, paths.toList(variables.lf), 'utf-8');
        cfformat.cftokensManifest('tokenize', fullManifestPath);
        var fileMap = {};
        for (var path in paths) {
            var hashKey = hash(path, 'md5', 'utf-8').lcase();
            fileMap[path] = fullTempPath & hashKey;
        }

        var stats = fileMapStats(fileMap, callback);
        directoryDelete(fullTempPath, true);
        return stats;
    }

    function fileMapStats(fileMap, callback) {
        var fileStats = {};
        var fileCount = fileMap.count();

        while (!fileMap.isEmpty()) {
            fileMap.each(function(src, target) {
                var success = true;
                var message = '';

                if (fileExists(target & '.json')) {
                    var tokenJSON = fileRead(target & '.json');
                    if (!isJSON(tokenJSON)) {
                        // file exists, but hasn't had JSON written out to it yet
                        return;
                    }
                    var tokens = deserializeJSON(tokenJSON);
                    try {
                        fileStats[src] = stats(tokens);
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
                    success,
                    message,
                    fileCount - fileMap.count(),
                    fileCount
                );
            });
        }

        return fileStats;
    }

    function stats(tokens) {
        var stats = {
            'lines': 0,
            'loc': 0,
            'methods': [],
            'properties': [],
            'tags': {},
            'bifs': {},
            'functioncalls': {},
            'methodcalls': {}
        };

        var isLoc = false;

        for (var i = 1; i <= tokens.len(); i++) {
            var token = tokens[i][1];
            var scopes = tokens[i][2].toList(' ');

            if (!isLoc && token.trim().len()) {
                isLoc = true;
            }

            if (token.endswith(chr(10))) {
                stats.lines++;
                if (isLoc) {
                    stats.loc++;
                }
                isLoc = false;
            }

            if (scopes.endsWith(functionNameScope)) {
                if (scopes.endsWith(methodScope)) {
                    stats.methods.append(token);
                } else if (reFind(tagMethodScopeRegex, scopes)) {
                    stats.methods.append(token);
                }
            } else if (scopes.endsWith(scriptPropertyNameScope)) {
                stats.properties.append(token);
            } else if (scopes.endsWith(functionScope)) {
                if (scopes.endsWith(functionCallScope)) {
                    stats.functioncalls[token] = (stats.functioncalls[token] ?: 0) + 1;
                } else if (scopes.endsWith(methodCallScope)) {
                    stats.methodcalls[token] = (stats.methodcalls[token] ?: 0) + 1;
                }
            } else if (scopes.endsWith(bifScope)) {
                stats.bifs[token] = (stats.bifs[token] ?: 0) + 1;
            } else if (
                scopes.endsWith(tagScope) ||
                (
                    scopes.endsWith(scriptTagScope) &&
                    !scopes.endsWith(scriptPropertyScope)
                )
            ) {
                var tag = token.startswith('cf') ? token : 'cf' & token;
                stats.tags[tag] = (stats.tags[tag] ?: 0) + 1;
            }
        }

        return stats;
    }

}
