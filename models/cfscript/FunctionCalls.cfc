component {

    property cfformat;
    property name="builtins";

    variables.anonFuncScopes = [
        'meta.function.anonymous.cfml',
        'meta.function.declaration.cfml',
        'storage.type.function.cfml'
    ];

    function init(cfformat) {
        variables.cfformat = cfformat;
        cfformat.cfscript.registerElement('function-call', this);
        cfformat.cfscript.register('support.function.', this);
        cfformat.cfscript.register('variable.function.', this);

        variables.builtins = deserializeJSON(fileRead(cfformat.getRootFolder() & 'data/functions.json')).reduce((r, f) => {
            r.cfdocs[f.lcase()] = f;
            r.pascal[f.lcase()] = reReplace(f, '(.)', '\u\1');
            return r;
        }, {'cfdocs': {}, 'pascal': {}});

        return this;
    }

    function print(
        cftokens,
        settings,
        indent,
        columnOffset
    ) {
        if (cftokens.peekScopeStartsWith('support.function.cfml')) {
            var token = cftokens.next(whitespace = false);
            var key = settings['function_call.casing.builtin'];
            if (len(key)) {
                return builtins[key][token[1].lcase()];
            }
            return token[1];
        }

        if (cftokens.peekScopeStartsWith('variable.function.cfml')) {
            var token = cftokens.next(whitespace = false);
            var key = settings['function_call.casing.userdefined'];
            if (len(key) && token[2][token[2].len() - 1] == 'meta.function-call.cfml') {
                var replacement = key == 'camel' ? '\l\1' : '\u\1';
                return reReplace(token[1], '(.)', replacement);
            }
            return token[1];
        }

        if (!cftokens.nextIsElement()) {
            return;
        }

        var element = cftokens.next(false);

        var printedElements = cfformat.delimited.printElements(element, settings, indent);
        var spacer = settings['function_call.padding'] ? ' ' : '';
        var delimiter = ', ';

        if (printedElements.endingComments.isEmpty()) {
            var tokenArrays = element.delimited_elements.map((tokens) => cfformat.cftokens(tokens));

            var anonFuncs = tokenArrays
                .map((_cftokens) => {
                    var token = _cftokens.peek(true);
                    return !isNull(token) && (
                        isArray(token) ? _cftokens.tokenMatches(token, anonFuncScopes) : token.type == 'function-parameters'
                    );
                })
                .toList();

            var structOrArray = tokenArrays
                .map((_cftokens) => {
                    var token = _cftokens.peek(true);
                    return (
                        !isNull(token) &&
                        isStruct(token) &&
                        ['struct', 'array'].find(token.type)
                    );
                })
                .toList();

            var inlineElements = [];
            var inlinePrint = false;

            // special case anonymous function arguments and single struct or array params
            if (anonFuncs == 'true' || structOrArray == 'true') {
                inlineElements.append(cfformat.cfscript.print(tokenArrays[1], settings, indent).trim());
                inlinePrint = true;
            } else if (anonFuncs == 'true,false') {
                inlineElements.append(cfformat.cfscript.print(tokenArrays[2], settings, indent + 1).trim());
                var anonFuncIndent = indent + 1;
                if (!inlineElements[1].find(chr(10))) {
                    anonFuncIndent--;
                    inlinePrint = true;
                }
                inlineElements.prepend(cfformat.cfscript.print(tokenArrays[1], settings, anonFuncIndent).trim());
            } else if (anonFuncs == 'false,true') {
                inlineElements.append(cfformat.cfscript.print(tokenArrays[1], settings, indent + 1).trim());
                var anonFuncIndent = indent + 1;
                if (!inlineElements[1].find(chr(10))) {
                    anonFuncIndent--;
                    inlinePrint = true;
                }
                inlineElements.append(cfformat.cfscript.print(tokenArrays[2], settings, anonFuncIndent).trim());
            }

            if (inlinePrint) {
                return '(' & spacer & inlineElements.tolist(delimiter) & spacer & ')';
            }
        }

        if (printedElements.printed.len() == 1 && printedElements.printed[1].trim() == '') {
            return settings['function_call.empty_padding'] ? '( )' : '()';
        }

        var formatted = '(' & spacer & printedElements.printed.tolist(delimiter) & spacer & ')';

        if (
            (
                printedElements.printed.len() < settings['function_call.multiline.element_count'] ||
                formatted.len() <= settings['function_call.multiline.min_length']
            ) &&
            !formatted.find(chr(10)) &&
            columnOffset + formatted.len() <= settings.max_columns
        ) {
            return formatted;
        }

        var formattedText = '(';
        formattedText &= cfformat.delimited.joinElements(
            'function_call',
            printedElements,
            settings,
            indent
        );
        formattedText &= settings.lf & cfformat.indentTo(indent, settings) & ')';
        return formattedText;
    }

}
