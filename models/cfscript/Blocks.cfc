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
        var element = cftokens.next(false);

        var blockFormatted = cfformat.cfscript
            .print(
                cfformat.cftokens(element.elements),
                settings,
                indent + 1,
                (indent + 1) * settings.indent_size
            )
            .trim();

        if (!blockFormatted.len()) {
            return '{' & settings.lf & cfformat.indentTo(indent, settings) & '}';
        }

        return '{' & settings.lf & cfformat.indentTo(indent + 1, settings) & blockFormatted & settings.lf & cfformat.indentTo(
            indent,
            settings
        ) & '}';
    }

}
