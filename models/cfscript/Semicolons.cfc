component {

    property cfformat;

    variables.terminator = ['punctuation.terminator.statement.cfml'];

    function init(cfformat) {
        variables.cfformat = cfformat;
        cfformat.cfscript.register('punctuation.terminator.statement.', this);
        return this;
    }

    function print(
        cftokens,
        settings,
        indent,
        columnOffset
    ) {
        if (cftokens.peekScopes(terminator)) {
            var formattedText = ';';

            // consume semicolon
            cftokens.next(false);

            // consume any non newline whitespace
            cftokens.consumeWhitespace();

            // if a line comment follows, insert a space instead of a newline
            if (cfformat.cfscript.comments.peekLineComment(cftokens)) {
                formattedText &= ' ';
            } else {
                formattedText &= settings.lf;

                // if a newline follows, consume it and any following whitespace
                if (cftokens.peekNewline()) {
                    cftokens.next(false);
                    cftokens.consumeWhitespace();
                }

                // if what follows is not another newline add an indent
                if (!cftokens.peekNewline()) {
                    formattedText &= cfformat.indentTo(indent, settings);
                }
            }

            return formattedText;
        }
    }

}
