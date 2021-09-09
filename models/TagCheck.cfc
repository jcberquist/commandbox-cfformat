component accessors="true" {

    function init(required any cfformat, required string lf) {
        variables.cfformat = arguments.cfformat;
        variables.nonClosingTags = variables.cfformat.getTagData().nonClosingTags;
        variables.lf = arguments.lf;
        return this;
    }

    function checkFile(fullFilePath) {
        var tokens = cfformat.cftokensFile('tokenize', fullFilePath);
        return check(tokens);
    }

    function checkFiles(paths, fullTempPath, callback) {
        directoryCreate(fullTempPath, true);

        var fullManifestPath = fullTempPath & 'manifest.txt';
        fileWrite(fullManifestPath, paths.toList(variables.lf), 'utf-8');
        cfformat.cftokensManifest('tokenize', fullManifestPath);
        var fileMap = {};
        for (var path in paths) {
            var hashKey = hash(path, 'md5', 'utf-8').lcase();
            fileMap[path] = fullTempPath & hashKey;
        }

        checkFileMap(fileMap, callback);
        directoryDelete(fullTempPath, true);
    }

    function checkFileMap(fileMap, callback) {
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
                        check(tokens);
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
    }

    function check(tokens) {
        var lineNum = 1;
        var tags = [];

        var currentTag = {};

        for (var i = 1; i <= tokens.len(); i++) {
            if (tokens[i][1].endswith(chr(10))) {
                lineNum++;
            }

            if (!tokens[i][2].len()) {
                continue;
            }

            if (tokens[i][2].some((t) => t.startswith('comment.block'))) {
                continue;
            }

            if (tokens[i][2].last().startswith('punctuation.definition.tag.begin')) {
                currentTag = {
                    closing: tokens[i][1] == '</',
                    name: '',
                    requiresClosing: true,
                    line: lineNum
                };
                var endScopes = tokens[i][2].slice(1, tokens[i][2].len() - 1);
                endScopes.append(tokens[i][2].last().replace('begin', 'end'));

                if (tokens[i + 1][2].last().startswith('entity.name.tag')) {
                    currentTag.name = tokens[++i][1].trim();
                    if (tokens[i][2].last() == 'entity.name.tag.custom.cfml') {
                        while (tokens[i + 1][2].find('entity.name.tag.custom.cfml')) {
                            currentTag.name &= tokens[++i][1];
                        }
                    }

                    // walk to end of tag
                    while (endScopes.toList() != tokens[i][2].toList()) {
                        i++;
                        if (tokens[i][1].endswith(chr(10))) {
                            lineNum++;
                        }
                    };
                    currentTag.requiresClosing = (
                        tokens[i][1] != '/>' &&
                        !nonClosingTags.cfml.contains(currentTag.name) &&
                        !nonClosingTags.html.contains(currentTag.name)
                    );
                }
            }

            if (!currentTag.isEmpty() && currentTag.name.len()) {
                if (!currentTag.closing) {
                    tags.append(currentTag);
                } else {
                    // closing tag, check for match
                    while (tags.len() && tags.last().name != currentTag.name && !tags.last().requiresClosing) {
                        tags.deleteAt(tags.len());
                    }

                    if (!tags.len()) {
                        throw('Closing </#currentTag.name#> on line #currentTag.line# has no matching opening tag.');
                    }

                    if (tags.last().name != currentTag.name) {
                        throw(
                            '<#tags.last().name#> on line #tags.last().line# does not match closing </#currentTag.name#> on line #currentTag.line#.'
                        );
                    }

                    tags.deleteAt(tags.len());
                }

                currentTag = {};
            }
        }

        while (tags.len() && !tags.last().requiresClosing) {
            tags.deleteAt(tags.len());
        }

        if (tags.len()) {
            throw('<#tags.last().name#> on line #tags.last().line# does not have a closing tag');
        }
    }

}
