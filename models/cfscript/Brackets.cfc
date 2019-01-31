component {

    property cfformat;

    function init(cfformat) {
        variables.cfformat = cfformat;
        cfformat.cfscript.registerElement('brackets', this);
        return this;
    }

    function print(
        cftokens,
        settings,
        indent,
        columnOffset
    ) {
        var element = cftokens.next(false);

        var bracketsFormatted = cfformat.cfscript
            .print(
                cfformat.cftokens(element.elements),
                settings,
                indent + 1,
                (indent + 1) * settings.indent_size
            )
            .trim();

        if (!bracketsFormatted.len()) {
            return '[]';
        }

        if (
            !bracketsFormatted.find(chr(10)) &&
            columnOffset + bracketsFormatted.len() <= settings.max_columns
        ) {
            var spacer = settings['brackets.padding'] ? ' ' : '';
            return '[' & spacer & bracketsFormatted & spacer & ']';
        }

        var elementNewLine = settings.lf & cfformat.indentTo(indent + 1, settings);
        var formattedText = '[' & elementNewLine & bracketsFormatted;
        formattedText &= settings.lf & cfformat.indentTo(indent, settings) & ']';
        return formattedText;
    }

}
