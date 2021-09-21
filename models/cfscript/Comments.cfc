component {

    property cfformat;

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
        columnOffset,
        lastChar = ''
    ) {
        if (peekLineComment(cftokens)) {
            // grab the `//`
            var token = cftokens.next(whitespace = false);

            // the rest of the line comment will be "one" token ending with a newline
            var formatted = cftokens.next()[1].rtrim();

            if (formatted.len() && formatted.len() == formatted.trim().len()) {
                formatted = ' ' & formatted;
            }

            formatted &= settings.lf;

            // consume following whitespace
            cftokens.consumeWhitespace();

            if (!cftokens.peekNewline()) {
                formatted &= cfformat.indentTo(indent, settings);
            }

            return (lastChar.trim().len() ? ' ' : '') & '//' & formatted;
        }

        if (!cftokens.nextIsElement()) return;

        var element = cftokens.next(false);

        // start by rendering literally
        var commentBody = element.elements
            .map((t) => {
                if (isStruct(t)) {
                    if (t.type.startswith('htmltag')) {
                        var tagTokens = cfformat.cftokens([t]);
                        return cfformat.cftags.print(tagTokens, settings, indent);
                    }
                } else {
                    if (t[1].endswith(chr(10))) {
                        return t[1].rtrim() & settings.lf;
                    }
                    return t[1];
                }
            })
            .toList('');
        var formatted = element.type == 'doc-comment' ? '/**' : '/*';
        formatted &= commentBody & '*/';


        // check to see if all lines after first start with `*`
        if (settings['comment.asterisks'] != 'ignored') {
            var lines = formatted.listToArray(chr(10), true);
            var starred = lines.len() > 1 && lines.slice(2).every((l) => l.ltrim().startswith('*'));

            // if they do, then align the starts
            if (starred) {
                var indentString = cfformat.indentTo(indent, settings);
                if (settings['comment.asterisks'] == 'align') {
                    indentString &= ' ';
                }
                var aligned = lines[1].rtrim() & settings.lf & indentString;
                aligned &= lines
                    .slice(2)
                    .map((l) => l.trim())
                    .toList(settings.lf & indentString);
                formatted = aligned;
            }
        }

        if (cftokens.peekNewline()) {
            formatted &= settings.lf;
            cftokens.next(false);
        }
        if (!cftokens.peekNewline()) {
            cftokens.consumeWhiteSpace();
            formatted &= cfformat.indentTo(indent, settings);
        }

        return (lastChar.trim().len() ? ' ' : '') & formatted;
    }

    function peekLineComment(cftokens, textOnly = false) {
        return cftokens.peekScopeStartsWith('punctuation.definition.comment.cfml', textOnly);
    }

}
