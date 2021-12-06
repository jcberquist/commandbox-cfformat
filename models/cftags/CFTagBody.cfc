component accessors="true" {

    property cfformat;

    function init(cfformat) {
        variables.cfformat = cfformat;
        cfformat.cftags.registerElement('cftag-body', this);
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

        var startTagTxt = cfformat.cftags.cftag.print(
            cfformat.cftokens([element.startTag]),
            settings,
            indent,
            columnOffset
        );
        formattedText &= startTagTxt;

        if (element.tagName == 'cfquery') {
            context = 'sql';
        }

        var bodyTokens = cfformat.cftokens(element.elements);
        var bodyIndent = context == 'sql' || element.tagName == 'cfscript' ? indent : indent + 1;

        if (element.tagName == 'cfscript') {
            var body = cfformat.cfscript.print(bodyTokens, settings, bodyIndent);
        } else {
            var body = cfformat.cftags.print(
                bodyTokens,
                settings,
                bodyIndent,
                bodyIndent * settings.indent_size,
                [],
                context
            );
        }

        // process the padding and indent surrounding the body
        if (element.tagName == 'cfscript') {
            body = settings.lf & cfformat.indentTo(bodyIndent, settings) & body.trim();
            body &= settings.lf & cfformat.indentTo(indent, settings);
        } else if (context == 'sql') {
            if (element.tagName == 'cfquery') {
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

        var endTagTxt = cfformat.cftags.cftag.print(
            cfformat.cftokens([element.endTag]),
            settings,
            indent,
            columnOffset
        );
        formattedText &= endTagTxt;

        if (context != 'sql' && !cftokens.peekNewline()) {
            cftokens.consumeWhitespace();
            formattedText &= settings.lf & cfformat.indentTo(indent, settings);
        }

        return formattedText;
    }

}
