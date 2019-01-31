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

        var bodyTokens = cfformat.cftokens(element.elements);

        if (element.tagName == 'cfscript') {
            var body = cfformat.cfscript.print(bodyTokens, settings, indent).trim();
        } else if (element.tagName == 'cfquery') {
            var body = cfformat.cftags
                .print(
                    bodyTokens,
                    settings,
                    indent,
                    indent * settings.indent_size,
                    [],
                    'sql'
                )
                .trim();
        } else {
            var body = cfformat.cftags
                .print(
                    bodyTokens,
                    settings,
                    indent + 1,
                    (indent + 1) * settings.indent_size,
                    [],
                    context
                )
                .trim();
        }

        if (element.tagName == 'cfscript' || element.tagName == 'cfquery') {
            formattedText &= settings.lf & cfformat.indentTo(indent, settings);
        } else if (containsTags || body.find(chr(10))) {
            formattedText &= settings.lf & cfformat.indentTo(indent + 1, settings);
        }

        formattedText &= body;

        if (
            containsTags ||
            element.tagName == 'cfscript' ||
            element.tagName == 'cfquery' ||
            body.find(chr(10))
        ) {
            formattedText &= settings.lf & cfformat.indentTo(indent, settings);
        }

        var endTagTxt = cfformat.cftags.cftag.print(
            cfformat.cftokens([element.endTag]),
            settings,
            indent,
            columnOffset
        );
        formattedText &= endTagTxt;

        if (!cftokens.peekText(chr(10))) {
            cftokens.consumeWhitespace();
            formattedText &= settings.lf & cfformat.indentTo(indent, settings);
        }

        return formattedText;
    }

}
