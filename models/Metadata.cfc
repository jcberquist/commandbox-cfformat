component accessors="true" {

    variables.attrEnd = {scopes: [], elements: ['block']};

    function init(required any cfformat) {
        variables.cfformat = arguments.cfformat;
        variables.printSettings = variables.cfformat.mergedSettings({})

        this.attributes = new metadata.Attributes(this);
        this.docblock = new metadata.Docblock(this);
        this.methods = new metadata.Methods(this);
        this.properties = new metadata.Properties(this);
        this.tagMethods = new metadata.TagMethods(this);
        this.tagProperties = new metadata.TagProperties(this);

        return this;
    }

    function cftokens(tokens) {
        return new CFTokens(tokens);
    }

    function parseFile(fullFilePath) {
        return parse(cfformat.cftokensFile('parse', fullFilePath));
    }

    function parseFiles(
        paths,
        fullTempPath,
    ) {
        directoryCreate(fullTempPath, true);

        var fullManifestPath = fullTempPath & 'manifest.txt';
        fileWrite(fullManifestPath, paths.toList(chr(10)), 'utf-8');
        cfformat.cftokensManifest('parse', fullManifestPath);

        var fileMap = {};
        for (var path in paths) {
            var hashKey = hash(path, 'md5', 'utf-8').lcase();
            fileMap[path] = fullTempPath & hashKey;
        }

        var result = parseFileMap(fileMap);

        directoryDelete(fullTempPath, true);
        return result;
    }

    function parseFileMap(fileMap) {
        var fileCount = fileMap.count();
        var results = {};
        while (!fileMap.isEmpty()) {
            fileMap.each(function(src, target) {

                if (fileExists(target & '.json')) {
                    var tokenJSON = fileRead(target & '.json', 'utf-8');
                    try {
                        var tokens = deserializeJSON(tokenJSON);
                    } catch (any e) {
                        // file exists, but hasn't had JSON written out to it yet
                        return;
                    }
                    try {
                        results[src] = parse(tokens);
                    } catch (any e) {
                        // success = false;
                        // message = e.message;
                    }
                } else if (fileExists(target & '.error')) {
                    // success = false;
                    // message = fileRead(target & '.error');
                } else {
                    return;
                }

                fileMap.delete(src);
            });
        }
        return results;
    }

    function parse(tokens) {
        var type = cfformat.determineFileType(tokens);
        var meta = {};

        if (type == 'cfscript') {
            var cftokens = this.cftokens(tokens.elements);
            // advance past component key word
            while (cftokens.hasNext()) {
                var token = cftokens.next();

                if (isStruct(token) && token.type == 'doc-comment') {
                    meta.append(this.docblock.parse(token));
                }

                if (isArray(token) && token[2].last() == 'storage.type.class.cfml') {
                    break;
                }
            }

            // collect component attributes
            var attributeTokens = cftokens.collectTo([], ['block']);
            meta.append(this.attributes.parse(attributeTokens));

            // now we do the component body
            meta['properties'] = [];
            meta['functions'] = [];
            var componentBody = cftokens.next(false, true);
            cftokens = this.cftokens(componentBody.elements);

            while (cftokens.hasNext()) {
                var nextToken = cftokens.peek();
                var docComment = {};

                if (isStruct(nextToken) && nextToken.type == 'doc-comment') {
                    docComment = this.docblock.parse(cftokens.next(false));
                    cftokens.consumeWhitespace(true);
                    nextToken = cftokens.peek();
                }

                if (
                    isArray(nextToken) &&
                    nextToken[2].toList(' ').endsWith('meta.tag.property.cfml entity.name.tag.script.cfml')
                ) {
                    // we have a property
                    cftokens.next(false);
                    var propertyTokens = [];
                    while (cftokens.hasNext()) {
                        var nextToken = cftokens.peek();
                        if (isArray(nextToken) && !nextToken[2].find('meta.tag.property.cfml')) {
                            break;
                        }
                        propertyTokens.append(cftokens.next(false));
                    }
                    var parsedProperty = this.properties.parse(this.cftokens(propertyTokens), docComment);
                    if (parsedProperty.keyExists('name')) {
                        meta.properties.append(parsedProperty);
                    }
                }

                if (
                    isArray(nextToken) &&
                    nextToken[2].find('meta.function.declaration.cfml')
                ) {
                    // we have a function declaration
                    meta.functions.append(this.methods.parse(cftokens, docComment));
                }

                cftokens.next(false);
            }
        } else if (type == 'cftags') {
            var cftokens = this.cftokens(cfformat.postProcess(tokens).elements);

            // find component tag
            while (cftokens.hasNext()) {
                var token = cftokens.next();
                if (isStruct(token) && token.tagName == 'cfcomponent') {
                    var componentTag = token;
                }
            }

            if (isNull(componentTag)) {
                return meta;
            }

            // component attributes
            var attributeTokens = this.cftokens(componentTag.starttag.elements);
            // move past the `cfcomponent` token
            attributeTokens.next();
            meta.append(this.attributes.parse(attributeTokens));

            // now we do the component body
            meta['properties'] = [];
            meta['functions'] = [];

            cftokens = this.cftokens(componentTag.elements);

            while (cftokens.hasNext()) {
                var token = cftokens.next();

                if (!isStruct(token)) {
                    continue;
                }

                if (token.type == 'cftag' && token.tagName == 'cfproperty') {
                    meta.properties.append(this.tagProperties.parse(token));
                } else if (token.type == 'cftag-body' && token.tagName == 'cffunction') {
                    meta.functions.append(this.tagMethods.parse(token));
                }
            }
        }

        return meta;
    }

    function convertToText(src) {
        var printed = variables.cfformat.cfscript.print(this.cftokens(src), variables.printSettings).trim();

        if (printed.startswith('"')) {
            printed = printed.mid(2, printed.len() - 2);
        } else if (printed.startswith('''')) {
            printed = printed.mid(2, printed.len() - 2);
        }

        return printed;
    }

}
