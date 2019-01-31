component {

    property cfformat;

    function init(cfformat) {
        variables.cfformat = cfformat;
        cfformat.cfscript.registerElement('array', this);
        return this;
    }

    function print(
        cftokens,
        settings,
        indent,
        columnOffset
    ) {
        var printedElements = cftokens
            .next(false)
            .delimited_elements.map((tokens) => {
                return cfformat.cfscript.print(cfformat.cftokens(tokens), settings, indent + 1).trim();
            });

        if (printedElements.len() == 1 && printedElements[1].trim() == '') {
            return settings['array.empty_padding'] ? '[ ]' : '[]';
        }

        var spacer = settings['array.padding'] ? ' ' : '';
        var delimiter = ', ';
        var formatted = '[' & spacer & printedElements.tolist(delimiter) & spacer & ']';
        if (
            (
                printedElements.len() < settings['array.multiline.element_count'] ||
                formatted.len() <= settings['array.multiline.min_length']
            ) &&
            !formatted.find(chr(10)) &&
            columnOffset + formatted.len() <= settings.max_columns
        ) {
            return formatted;
        }

        var elementNewLine = settings.lf & cfformat.indentTo(indent + 1, settings);
        if (settings['array.multiline.leading_comma']) {
            var formattedText = '[' & elementNewLine & repeatString(' ', delimiter.len()) & printedElements.tolist(
                elementNewLine & delimiter
            );
        } else {
            var formattedText = '[' & elementNewLine & printedElements.tolist(',' & elementNewLine);
        }
        formattedText &= settings.lf & cfformat.indentTo(indent, settings) & ']';
        return formattedText;
    }

}
