component {

    property cfformat;

    function init(cfformat) {
        variables.cfformat = cfformat;
        cfformat.cfscript.registerElement('block', this);
        return this;
    }

    function print(
        cftokens,
        settings,
        indent,
        columnOffset
    ) {
        var element = cftokens.next(false, true);

        var blockFormatted = cfformat.cfscript
            .print(
                cfformat.cftokens(element.elements),
                settings,
                indent + 1,
                (indent + 1) * settings.indent_size
            )
            .trim();

        var newlineIndent = settings.lf & cfformat.indentTo(indent, settings);

        var formatted = '{';
        if (blockFormatted.len()) {
            formatted &= settings.lf & cfformat.indentTo(indent + 1, settings);
            formatted &= blockFormatted;
        }
        formatted &= newlineIndent & '}' & settings.lf;

        if (cftokens.peekNewline()) {
            cftokens.next(false);
        }

        cftokens.consumeWhitespace(false);

        if (!cftokens.peekNewline()) {
            formatted &= cfformat.indentTo(indent, settings);
        }

        return formatted;
    }

}
