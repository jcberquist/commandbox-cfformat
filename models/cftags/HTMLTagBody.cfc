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
        columnOffset
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

        var bodyTokens = cfformat.cftokens(element.elements);
        var body = cfformat.cftags.print(bodyTokens, settings, indent + 1).trim();

        if (containsTags || body.find(chr(10))) {
            body = settings.lf & cfformat.indentTo(indent + 1, settings) & body.trim();
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

        if (!cftokens.peekNewline() && blockTags.findNoCase(element.tagName)) {
            cftokens.consumeWhitespace();
            formattedText &= settings.lf & cfformat.indentTo(indent, settings);
        }

        return formattedText;
    }

}
