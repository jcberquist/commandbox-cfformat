component {

    property cfformat;

    variables.structKey = 'meta.struct-literal.key.cfml';
    variables.structKeyValue = ['meta.struct-literal.cfml', 'punctuation.separator.key-value.cfml'];
    variables.functionStructKeyValue = [
        'meta.struct-literal.cfml',
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

        if (cftokens.peekScopes(structKeyValue) || cftokens.peekScopes(functionStructKeyValue)) {
            var token = cftokens.next(whitespace = false);
            cftokens.consumeWhiteSpace(true);
            return settings['struct.separator'];
        }

        if (!cftokens.peekElement('struct')) return;

        var printedElements = cfformat.delimited.printElements(cftokens.next(false), settings, indent);

        if (printedElements.printed.len() == 1 && printedElements.printed[1].trim() == '') {
            return settings['struct.empty_padding'] ? '{ }' : '{}';
        }

        var spacer = settings['struct.padding'] ? ' ' : '';
        var delimiter = ', ';

        if (printedElements.endingComments.isEmpty() && printedElements.afterCommaComments.isEmpty()) {
            var formatted = '{' & spacer & printedElements.printed.tolist(delimiter) & spacer & '}';
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

        var formattedText = '{';
        formattedText &= cfformat.delimited.joinElements(
            'struct',
            printedElements,
            settings,
            indent
        );
        formattedText &= settings.lf & cfformat.indentTo(indent, settings) & '}';
        return formattedText;
    }

}
