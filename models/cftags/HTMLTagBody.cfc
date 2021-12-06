component accessors="true" {

    property cfformat;

    function init(cfformat) {
        variables.cfformat = cfformat;
        variables.blockTags = cfformat.getTagData().blockTags.html;
        cfformat.cftags.registerElement('htmltag-body', this);
        return this;
    }

    function print(
        cftokens,
        settings,
        indent,
        columnOffset,
        context = 'base'
    ) {
        var element = cftokens.next(false);
        var containsTags = element.elements.some((e) => isStruct(e) && (e.type.startswith('cftag') || e.type.startswith('htmltag')));

        var formattedText = '';

        var startTagTxt = cfformat.cftags.htmltag.print(
            cfformat.cftokens([element.startTag]),
            settings,
            indent,
            columnOffset
        );
        formattedText &= startTagTxt;

        if (element.tagName == 'script') {
            context = 'javascript';
        }

        var bodyTokens = cfformat.cftokens(element.elements);
        var bodyIndent = context == 'javascript' ? indent : indent + 1;

        var body = cfformat.cftags.print(
            bodyTokens,
            settings,
            bodyIndent,
            bodyIndent * settings.indent_size,
            [],
            context
        );

        // process the padding and indent surrounding the body
        if (context == 'javascript') {
            if (element.tagName == 'script') {
                if (containsTags || body.find(chr(10))) {
                    body = body.rtrim() & settings.lf & cfformat.indentTo(indent, settings);
                }
            } else {
                body = cfformat.trailingIndentTo(body, bodyIndent, settings);
            }
        } else if (containsTags || body.find(chr(10))) {
            body = settings.lf & cfformat.indentTo(bodyIndent, settings) & body.trim();
            body &= settings.lf & cfformat.indentTo(indent, settings);
        }

        formattedText &= body;

        var endTagTxt = cfformat.cftags.htmltag.print(
            cfformat.cftokens([element.endTag]),
            settings,
            indent,
            columnOffset
        );
        formattedText &= endTagTxt;

        if (context != 'javascript' && !cftokens.peekNewline() && blockTags.findNoCase(element.tagName)) {
            cftokens.consumeWhitespace();
            formattedText &= settings.lf & cfformat.indentTo(indent, settings);
        }

        return formattedText;
    }

}
