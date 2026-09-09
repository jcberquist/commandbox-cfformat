component {

    property cfformat;

    variables.structKey = 'meta.struct-literal.key.cfml';
    variables.structKeyValue = ['meta.struct-literal.cfml', 'punctuation.separator.key-value.cfml'];
    variables.orderedStructKeyValue = ['meta.mapping.cfml', 'punctuation.separator.key-value.cfml'];
    variables.functionStructKeyValue = [
        'meta.struct-literal.cfml',
        'meta.function.declaration.cfml',
        'punctuation.separator.key-value.cfml'
    ];
    variables.orderedFunctionStructKeyValue = [
        'meta.mapping.cfml',
        'meta.function.declaration.cfml',
        'punctuation.separator.key-value.cfml'
    ];

    function init(cfformat) {
        variables.cfformat = cfformat;
        cfformat.cfscript.registerElement('struct', this);
        cfformat.cfscript.register('meta.struct-literal.key.', this);
        cfformat.cfscript.register('punctuation.separator.key-value.', this);
        return this;
    }

    function print(
        cftokens,
        settings,
        indent,
        columnOffset
    ) {
        if (cftokens.peekScopeStartsWith(structKey)) {
            var token = cftokens.next(whitespace = false);
            if (settings['struct.quote_keys']) {
                var quote = settings['strings.quote'] == 'double' ? '"' : '''';
                return quote & token[1] & quote;
            }
            return token[1];
        }

        if (
            cftokens.peekScopes(structKeyValue) ||
            cftokens.peekScopes(orderedStructKeyValue) ||
            cftokens.peekScopes(functionStructKeyValue) ||
            cftokens.peekScopes(orderedFunctionStructKeyValue)
        ) {
            var token = cftokens.next(whitespace = false);
            cftokens.consumeWhiteSpace(true);
            return settings['struct.separator'];
        }

        if (!cftokens.peekElement('struct')) return;

        var element = cftokens.next(false);
        var printedElements = cfformat.delimited.printElements(element, settings, indent);

        var openBracket = '{';
        var closeBracket = '}';
        if (isOrdered(element)) {
            openBracket = '[';
            closeBracket = ']';
        }

        if (!printedElements.printed.len()) {
            return settings['struct.empty_padding'] ? openBracket & ' ' & closeBracket : openBracket & closeBracket;
        }

        var spacer = settings['struct.padding'] ? ' ' : '';
        var delimiter = ', ';

        if (printedElements.endingComments.isEmpty() && printedElements.afterCommaComments.isEmpty()) {
            var formatted = openBracket & spacer & printedElements.printed.tolist(delimiter) & spacer & closeBracket;
            if (
                (
                    printedElements.printed.len() < settings['struct.multiline.element_count'] ||
                    formatted.len() <= settings['struct.multiline.min_length']
                ) &&
                !formatted.find(chr(10)) &&
                columnOffset + formatted.len() <= settings.max_columns
            ) {
                return formatted;
            }
        }

        var formattedText = openBracket;
        formattedText &= cfformat.delimited.joinElements(
            'struct',
            printedElements,
            settings,
            indent
        );
        formattedText &= settings.lf & cfformat.indentTo(indent, settings) & closeBracket;
        return formattedText;
    }

    private boolean function isOrdered(element) {
        for (var group in element.delimited_elements) {
            for (var token in group) {
                if (isArray(token) && token[2].find('meta.mapping.cfml')) return true;
            }
        }
        return false;
    }

}
