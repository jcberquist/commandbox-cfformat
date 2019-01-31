component {

    property cfformat;

    variables.attrNameScope = [['entity.other.attribute-name.html'], ['entity.other.attribute-name.class.html']];
    variables.attrAssignmentScope = ['punctuation.separator.key-value.html'];

    function init(cfformat) {
        variables.cfformat = cfformat;
        return this;
    }

    function printAttributes(
        cftokens,
        settings,
        indent,
        columnOffset
    ) {
        var attributeStrings = [];
        while (cftokens.hasNext()) {
            if (cftokens.peekScopeStartsWith('entity.other.attribute-name', true)) {
                var attr = printAttribute(cftokens, settings, indent + 1);

                attributeStrings.append(attr);
            } else {
                var txt = cfformat.cftags.print(
                    cftokens,
                    settings,
                    indent + 1,
                    (indent + 1) * settings.indent_size,
                    ['entity.other.attribute-name']
                );
                attributeStrings.append(txt.trim());
            }
        }

        if (!attributeStrings.len()) {
            return '';
        }

        var formattedText = attributeStrings.toList(' ');

        if (
            !formattedText.find(chr(10)) &&
            columnOffset + formattedText.len() <= settings.max_columns
        ) {
            return formattedText;
        }

        var elementNewLine = settings.lf & cfformat.indentTo(indent + 1, settings);
        var formattedText = elementNewLine & attributeStrings.tolist(elementNewLine);
        formattedText &= settings.lf & cfformat.indentTo(indent, settings);
        return formattedText;
    }

    function printAttribute(
        cftokens,
        settings,
        indent,
        columnOffset
    ) {
        var formattedText = cftokens.next(false, true)[1];

        if (!cftokens.peekScopeStartsWith('punctuation.separator.key-value', true)) {
            return formattedText;
        }

        // collect the '='
        formattedText &= cftokens.next(false, true)[1];

        // stop at the next attribute name
        formattedText &= cfformat.cftags
            .print(
                cftokens,
                settings,
                indent,
                indent * settings.indent_size,
                attrNameScope
            )
            .trim()

        return formattedText.trim();
    }

}
