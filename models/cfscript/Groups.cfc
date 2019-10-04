component {

    property cfformat;

    function init(cfformat) {
        variables.cfformat = cfformat;
        cfformat.cfscript.registerElement('group', this);
        return this;
    }

    function print(
        cftokens,
        settings,
        indent,
        columnOffset,
        lastChar,
        padding = settings['parentheses.padding'],
        emptyPadding = true
    ) {
        var element = cftokens.next(false);

        var groupFormatted = cfformat.cfscript
            .print(
                cfformat.cftokens(element.elements),
                settings,
                indent + 1,
                (indent + 1) * settings.indent_size
            )
            .trim();

        if (!groupFormatted.len()) {
            return '(' & (emptyPadding ? ' ' : '') & ')';
        }

        var endsWithLineComment = (
            element.elements.len() &&
            isArray(element.elements.last()) &&
            element.elements.last()[2].last() == 'comment.line.double-slash.cfml'
        );

        if (
            !groupFormatted.find(chr(10)) &&
            !endsWithLineComment &&
            columnOffset + groupFormatted.len() <= settings.max_columns
        ) {
            var spacer = padding ? ' ' : '';
            return '(' & spacer & groupFormatted & spacer & ')';
        }

        var elementNewLine = settings.lf & cfformat.indentTo(indent + 1, settings);
        var formattedText = '(' & elementNewLine & groupFormatted;
        formattedText &= settings.lf & cfformat.indentTo(indent, settings) & ')';
        return formattedText;
    }

}
