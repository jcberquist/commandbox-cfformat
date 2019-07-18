component {

    property cfformat;

    variables.functionStart = ['meta.function.declaration.cfml', '*'];
    variables.attrEnd = {scopes: ['punctuation.terminator.statement.cfml'], elements: ['block']};

    function init(cfformat) {
        variables.cfformat = cfformat;
        cfformat.cfscript.register('storage.', this);
        cfformat.cfscript.registerElement('function-parameters', this);
        return this;
    }

    function print(
        cftokens,
        settings,
        indent,
        columnOffset
    ) {
        if (cftokens.peekScopes(functionStart)) {
            var words = [];

            while (!cftokens.nextIsElement()) {
                var token = cftokens.next(false)
                words.append(token[1]);
            }

            var formattedText = words.toList(' ');
            var rootSettingKey = token[2].last() == 'entity.name.function.cfml' ? 'function_declaration' : 'function_anonymous';

            // parameters
            var parametersTxt = printFunctionParameters(
                cftokens.next(false),
                settings,
                indent,
                columnOffset + formattedText.len(),
                rootSettingKey
            );

            columnOffset += parametersTxt.len();
            formattedText &= parametersTxt;

            // handle tag metadata after function parameters
            var attributesTxt = cfformat.cfscript.attributes.printAttributes(
                cftokens,
                settings,
                indent,
                columnOffset + formattedText.len(),
                attrEnd
            );
            if (attributesTxt.len()) {
                attributesTxt = ' ' & attributesTxt;
                columnOffset += attributesTxt.len();
                formattedText &= attributesTxt;
            }

            cftokens.consumeWhitespace(true);

            if (cftokens.peekScopes(['punctuation.terminator.statement.cfml'])) {
                return formattedText;
            }

            if (
                settings['#rootSettingKey#.group_to_block_spacing'] == 'spaced' &&
                !attributesTxt.find(chr(10))
            ) {
                formattedText = formattedText & ' ';
            } else if (settings['#rootSettingKey#.group_to_block_spacing'] == 'newline') {
                formattedText &= settings.lf & cfformat.indentTo(indent, settings);
            }

            var blockTxt = cfformat.cfscript.blocks.print(cftokens, settings, indent);
            formattedText &= blockTxt;


            return formattedText;
        }

        if (cftokens.peekElement('function-parameters')) {
            var parametersElement = cftokens.next(false);
            var arrowToken = cftokens.next(false);

            // arrow function parameters
            var formattedText = printFunctionParameters(
                parametersElement,
                settings,
                indent,
                columnOffset,
                'function_anonymous'
            );

            // add the arrow `=>`
            formattedText &= ' => ';

            columnOffset += formattedText.len();
            cftokens.consumeWhitespace(true);

            if (cftokens.peekElement('block')) {
                var blockTxt = cfformat.cfscript.blocks.print(cftokens, settings, indent);
                formattedText &= blockTxt;
            } else {
                var baseScopes = arrowToken[2]
                    .slice(1, arrowToken[2].len() - 2)
                    .append('meta.function.body.cfml')
                    .toList();
                var tokens = [];
                while (cftokens.hasNext()) {
                    if (!cftokens.nextIsElement()) {
                        var nextToken = cftokens.peek();
                        if (!isNull(nextToken)) {
                            var peekTokenScopes = cftokens.peek()[2].toList();
                            if (!peekTokenScopes.startsWith(baseScopes)) break;
                        }
                    }
                    tokens.append(cftokens.next());
                }
                formattedText &= cfformat.cfscript.print(
                    cfformat.cftokens(tokens),
                    settings,
                    indent,
                    columnOffset
                );
            }

            return formattedText;
        }
    }

    function printFunctionParameters(
        element,
        settings,
        indent,
        columnOffset,
        rootSettingKey
    ) {
        var printedElements = cfformat.delimited.printElements(element, settings, indent);

        if (printedElements.printed.len() == 1 && printedElements.printed[1].trim() == '') {
            return settings['#rootSettingKey#.empty_padding'] ? '( )' : '()';
        }

        var spacer = settings['#rootSettingKey#.padding'] ? ' ' : '';
        var delimiter = ', ';
        var formatted = '(' & spacer & printedElements.printed.tolist(delimiter) & spacer & ')';

        if (
            (
                printedElements.printed.len() < settings['#rootSettingKey#.multiline.element_count'] ||
                formatted.len() <= settings['#rootSettingKey#.multiline.min_length']
            ) &&
            !formatted.find(chr(10)) &&
            columnOffset + formatted.len() <= settings.max_columns
        ) {
            return formatted;
        }

        var formattedText = '(';
        formattedText &= cfformat.delimited.joinElements(
            rootSettingKey,
            printedElements,
            settings,
            indent
        );
        formattedText &= settings.lf & cfformat.indentTo(indent, settings) & ')';
        return formattedText;
    }

}
