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
            return ': ';
        }

        if (!cftokens.peekElement('struct')) return;

        var printedElements = cftokens
            .next(false)
            .delimited_elements.map((tokens) => {
                return cfformat.cfscript.print(cfformat.cftokens(tokens), settings, indent + 1).trim();
            });

        if (printedElements.len() == 1 && printedElements[1].trim() == '') {
            return settings['struct.empty_padding'] ? '{ }' : '{}';
        }

        var spacer = settings['struct.padding'] ? ' ' : '';
        var delimiter = ', ';
        var formatted = '{' & spacer & printedElements.tolist(delimiter) & spacer & '}';
        if (
            (
                printedElements.len() < settings['struct.multiline.element_count'] ||
                formatted.len() <= settings['struct.multiline.min_length']
            ) &&
            !formatted.find(chr(10)) &&
            columnOffset + formatted.len() <= settings.max_columns
        ) {
            return formatted;
        }

        var elementNewLine = settings.lf & cfformat.indentTo(indent + 1, settings);
        if (settings['struct.multiline.leading_comma']) {
            var formattedText = '{' & elementNewLine & repeatString(' ', delimiter.len()) & printedElements.tolist(
                elementNewLine & delimiter
            );
        } else {
            var formattedText = '{' & elementNewLine & printedElements.tolist(',' & elementNewLine);
        }
        formattedText &= settings.lf & cfformat.indentTo(indent, settings) & '}';
        return formattedText;
    }

}
