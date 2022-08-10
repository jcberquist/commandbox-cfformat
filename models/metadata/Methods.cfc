component {

    function init(metadata) {
        variables.metadata = arguments.metadata;
    }

    function parse(cftokens, docComment = {}) {
        var meta = {};

        while (cftokens.hasNext()) {
            var token = cftokens.next();

            if (isArray(token)) {
                if (token[2].last().startswith('storage.modifier.cfml')) {
                    var word = token[1];

                    if (
                        [
                            'public',
                            'private',
                            'package',
                            'remote'
                        ].find(word.lcase())
                    ) {
                        meta['access'] = word;
                    } else if (word.lcase() == 'static') {
                        meta['static'] = true;
                    }
                }

                if (token[2].last().startswith('storage.type')) {
                    var word = token[1];
                    if (word.lcase() != 'function') {
                        meta['returntype'] = word;
                    }
                }

                if (token[2].last().startswith('entity.name.function')) {
                    meta['name'] = token[1];
                }
            }

            if (isStruct(token) && token.type == 'function-parameters') {
                if (arrayLen(token.delimited_elements) == 1 && arrayIsEmpty(token.delimited_elements[1])) {
                    meta['parameters'] = [];
                } else {
                    meta['parameters'] = token.delimited_elements.map(parseParameter);
                    // check for whitespace
                    if (meta.parameters.len() == 1 && structIsEmpty(meta.parameters[1])) {
                        meta.parameters = [];
                    }
                }
                break;
            }
        }

        // collect method attributes
        var attributeTokens = cftokens.collectTo([], ['block']);
        meta.append(variables.metadata.attributes.parse(attributeTokens));

        // handle doc block
        for (var param in meta.parameters) {
            if (docComment.keyExists(param.name)) {
                param['hint'] = docComment[param.name];
                docComment.delete(param.name);
            }
            for (var key in docComment) {
                if (listFirst(key, '.') == param.name) {
                    param[listRest(key, '.')] = docComment[key];
                    docComment.delete(key);
                }
            }
        }
        meta.append(docComment);

        return meta;
    }

    function parseParameter(elements) {
        var cftokens = variables.metadata.cftokens(elements);
        var meta = {};

        while (cftokens.hasNext()) {
            var nextToken = cftokens.peek();

            if (!isNull(nextToken) && isArray(nextToken)) {
                if (nextToken[2].last().startswith('keyword.other.required.parameter')) {
                    meta['required'] = true;
                    cftokens.next(false, true);
                    continue;
                } else if (nextToken[2].last().startswith('storage.type')) {
                    meta['type'] = cftokens.next(false, true)[1];
                    continue;
                } else if (nextToken[2].last().startswith('variable.parameter.function')) {
                    meta['name'] = cftokens.next(false, true)[1];
                    break;
                }
            }

            cftokens.next();
        }

        // check for default value
        var nextToken = cftokens.peek();
        if (!isNull(nextToken) && isArray(nextToken)) {
            if (nextToken[2].last().startsWith('keyword.operator.assignment.binary')) {
                cftokens.next(false, true);
                var elements = [];
                while (
                    cftokens.hasNext() &&
                    !cftokens.peekScopeStartsWith('entity.other.attribute-name')
                ) {
                    elements.append(cftokens.next());
                }
                meta['default'] = variables.metadata.convertToText(elements);
            }
        }

        // anything left is tag attributes
        meta.append(metadata.attributes.parse(cftokens));

        return meta;
    }

}
