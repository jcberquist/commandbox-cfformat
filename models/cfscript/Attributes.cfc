component {

    property cfformat;

    variables.attrNameScope = [
        ['entity.other.attribute-name.cfml'],
        ['entity.other.attribute-name.cfml', 'storage.modifier.extends.cfml']
    ];
    variables.attrAssignmentScope = ['punctuation.separator.key-value.cfml'];
    variables.cfAttrCommaScope = ['meta.tag.script.cf.attributes.cfml', 'punctuation.separator.comma.cfml'];

    function init(cfformat) {
        variables.cfformat = cfformat;
        cfformat.cfscript.register('punctuation.separator.comma', this);
        return this;
    }

    function print(
        cftokens,
        settings,
        indent,
        columnOffset
    ) {
        if (!cftokens.peekScopes(cfAttrCommaScope)) return;
        cftokens.next(false);
        cftokens.consumeWhitespace(true);
        return '';
    }

    function printAttributes(
        cftokens,
        settings,
        indent,
        columnOffset,
        attributesEnd
    ) {
        if (!isNull(arguments.attributesEnd)) {
            var attributeTokens = cftokens.collectTo(argumentCollection = attributesEnd);
        } else {
            var attributeTokens = cftokens;
        }

        var attributeStrings = [];
        while (attributeTokens.hasNext()) {
            var attr = printAttribute(attributeTokens, settings, indent + 1);
            if (!isNull(attr)) {
                attributeStrings.append(attr);
            } else {
                break;
            };
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
        if (
            !cftokens.peekScopeStartsWith('entity.other.attribute-name', true) &&
            !cftokens.peekScopeStartsWith('storage.modifier.extends', true)
        )
            return;

        var formattedText = cftokens.next(false, true)[1];

        if (!cftokens.peekScopeStartsWith('punctuation.separator.key-value', true)) {
            return formattedText;
        }

        // collect the '='
        formattedText &= cftokens.next(false, true)[1];

        // stop at the next attribute name
        formattedText &= cfformat.cfscript
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
