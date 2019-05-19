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
        var printedElements = cfformat.delimited.printElements(cftokens.next(false), settings, indent);

        if (printedElements.printed.len() == 1 && printedElements.printed[1].trim() == '') {
            return settings['array.empty_padding'] ? '[ ]' : '[]';
        }

        var spacer = settings['array.padding'] ? ' ' : '';
        var delimiter = ', ';

        if (printedElements.endingComments.isEmpty()) {
            var formatted = '[' & spacer & printedElements.printed.tolist(delimiter) & spacer & ']';
            if (
                (
                    printedElements.printed.len() < settings['array.multiline.element_count'] ||
                    formatted.len() <= settings['array.multiline.min_length']
                ) &&
                !formatted.find(chr(10)) &&
                columnOffset + formatted.len() <= settings.max_columns
            ) {
                return formatted;
            }
        }

        var formattedText = '[';
        formattedText &= cfformat.delimited.joinElements(
            'array',
            printedElements,
            delimiter,
            settings,
            indent
        );
        formattedText &= settings.lf & cfformat.indentTo(indent, settings) & ']';
        return formattedText;
    }

}
