component {

    property cfformat;

    variables.structKeyValue = ['meta.struct-literal.cfml', 'punctuation.separator.key-value.cfml'];

    function init(cfformat) {
        variables.cfformat = cfformat;
        cfformat.cfscript.registerElement('struct', this);
        cfformat.cfscript.register('punctuation.separator.key-value.', this);
        return this;
    }

    function print(
        cftokens,
        settings,
        indent,
        columnOffset
    ) {
        if (cftokens.peekScopes(structKeyValue)) {
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
