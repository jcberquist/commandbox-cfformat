component {

    property cfformat;

    variables.functionStart = ['meta.function.declaration.cfml', '*'];
    variables.attrEnd = {scopes: [['punctuation.terminator.statement.cfml']], elements: ['block']};

    function init(cfformat) {
        variables.cfformat = cfformat;
        cfformat.cfscript.register('storage.', this);
        cfformat.cfscript.registerElement('function-parameters', this);
        cfformat.cfscript.register('variable.parameter.function.cfml', this);
        return this;
    }

    function print(
        cftokens,
        settings,
        indent,
        columnOffset
    ) {
        if (
            cftokens.peekScopes(functionStart) &&
            !cftokens.peekScopeStartsWith('variable.parameter.function.cfml')
        ) {
            var words = [];

            while (!cftokens.nextIsElement()) {
                var token = cftokens.next(false);
                words.append(token[1]);
            }

            var formattedText = words.toList(' ');
            var rootSettingKey = token[2].last() == 'entity.name.function.cfml' ? 'function_declaration' : 'function_anonymous';

            // spacing_to_group
            if (settings['#rootSettingKey#.spacing_to_group']) {
                formattedText &= ' ';
            }

            // parameters
            var parametersTxt = printFunctionParameters(
                cftokens.next(false),
                settings,
                indent,
                columnOffset + formattedText.len(),
                rootSettingKey
            );

            formattedText &= parametersTxt;
            columnOffset = cfformat.nextOffset(columnOffset, formattedText, settings);

            // handle tag metadata after function parameters
            var attributesTxt = cfformat.cfscript.attributes.printAttributes(
                cftokens,
                settings,
                indent,
                columnOffset,
                attrEnd,
                false,
                'metadata'
            );

            if (attributesTxt.len()) {
                attributesTxt = (attributesTxt.find(chr(10)) ? '' : ' ') & attributesTxt;
                columnOffset = cfformat.nextOffset(columnOffset, attributesTxt, settings);
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

        if (
            cftokens.peekElement('function-parameters') ||
            (
                cftokens.peekScopes(functionStart) &&
                cftokens.peekScopeStartsWith('variable.parameter.function.cfml')
            )
        ) {
            var parametersElement = cftokens.next(false);
            var arrowToken = cftokens.next(false);

            // arrow function parameters
            if (isStruct(parametersElement)) {
                var formattedText = printFunctionParameters(
                    parametersElement,
                    settings,
                    indent,
                    columnOffset,
                    'function_anonymous'
                );
            } else {
                var formattedText = parametersElement[1];
            }

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

                if (formattedText.reFind('\n[ \t]*$')) {
                    cftokens.consumeWhitespace();
                }
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

        if (!printedElements.printed.len()) {
            return settings['#rootSettingKey#.empty_padding'] ? '( )' : '()';
        }

        var spacer = settings['#rootSettingKey#.padding'] ? ' ' : '';
        var delimiter = ', ';

        if (printedElements.endingComments.isEmpty() && printedElements.afterCommaComments.isEmpty()) {
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
