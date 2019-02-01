component {

    property cfformat;

    variables.lineCommentStart = ['comment.line.double-slash.cfml', 'punctuation.definition.comment.cfml'];

    function init(cfformat) {
        variables.cfformat = cfformat;
        cfformat.cfscript.register('punctuation.definition.comment.', this);
        cfformat.cfscript.registerElement('doc-comment', this);
        cfformat.cfscript.registerElement('block-comment', this);
        return this;
    }

    function print(
        cftokens,
        settings,
        indent,
        columnOffset
    ) {
        if (cftokens.peekScopes(lineCommentStart)) {
            // grab the `//`
            var token = cftokens.next(whitespace = false);

            // the rest of the line comment will be "one" token ending with a newline
            var formatted = cftokens.next()[1].trim();

            // consume following whitespace
            cftokens.consumeWhiteSpace();

            return '// ' & formatted & settings.lf & cfformat.indentTo(indent, settings);
        }

        if (!cftokens.nextIsElement()) return;

        var element = cftokens.next(false);

        var lines = element.elements
            .map((t) => {
                if (isStruct(t)) {
                    if (t.type.startswith('htmltag')) {
                        var tagTokens = cfformat.cftokens([t]);
                        return cfformat.cftags.print(tagTokens, settings, indent);
                    }
                } else {
                    return t[1];
                }
            })
            .toList('')
            .trim()
            .listToArray(chr(10));

        if (
            element.type == 'block-comment' &&
            lines.len() == 1 &&
            lines[1].trim().len() + columnOffset + 6 <= settings.max_columns// count /* and */
        ) {
            var txt = lines[1].trim();
            var spacer = txt.startswith('*') ? '' : ' ';
            var formatted = '/*' & spacer & txt & spacer & '*/';
        } else {
            lines = lines.map((line) => {
                line = line.trim();
                if (element.type == 'doc-comment' && (!line.len() || line.mid(1, 1) != '*')) {
                    line = '* ' & line;
                }
                if (element.type == 'block-comment' && line.len()) {
                    line = '  ' & line;
                }
                return cfformat.indentTo(indent, settings) & line;
            });

            var formatted = element.type == 'doc-comment' ? '/**' : '/*';
            formatted &= settings.lf;
            formatted &= lines.toList(settings.lf);
            formatted &= settings.lf & cfformat.indentTo(indent, settings) & '*/';
        }

        if (cftokens.peekNewline()) {
            formatted &= settings.lf;
            cftokens.next(false);
        }
        if (!cftokens.peekNewline()) {
            cftokens.consumeWhiteSpace();
            formatted &= cfformat.indentTo(indent, settings);
        }

        return formatted;
    }

}
