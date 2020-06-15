component {

    property cfformat;

    variables.attrNameScope = [
        ['entity.other.attribute-name.cfml'],
        ['entity.other.attribute-name.cfml', 'storage.modifier.extends.cfml']
    ];
    variables.attrAssignmentScope = ['punctuation.separator.key-value.cfml'];
    variables.cfAttrNameScope = ['meta.tag.script.cf.attributes.cfml', 'entity.other.attribute-name.cfml'];
    variables.cfAttrCommaScope = ['meta.tag.script.cf.attributes.cfml', 'punctuation.separator.comma.cfml'];

    function init(cfformat) {
        variables.cfformat = cfformat;
        cfformat.cfscript.register('punctuation.separator.comma', this);
        cfformat.cfscript.register('entity.other.attribute-name', this);
        return this;
    }

    function print(
        cftokens,
        settings,
        indent,
        columnOffset
    ) {
        if (cftokens.peekScopes(cfAttrCommaScope)) {
            cftokens.next(false);
            cftokens.consumeWhitespace(true);
            return '';
        }
        if (cftokens.peekScopes(cfAttrNameScope)) {
            return printAttribute(
                cftokens,
                settings,
                indent,
                columnOffset,
                settings['binary_operators.padding']
            );
        }
    }

    function printAttributes(
        cftokens,
        settings,
        indent,
        columnOffset,
        attributesEnd,
        commaDelimited = false,
        tagSetting = ''
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
            }
        }

        if (!attributeStrings.len()) {
            return '';
        }

        var formattedText = attributeStrings.toList(commaDelimited ? ', ' : ' ');
        var min_length = tagSetting.len() ? settings['#tagSetting#.multiline.min_length'] : 0;
        var element_count = tagSetting.len() ? settings['#tagSetting#.multiline.element_count'] : 100;

        if (
            (
                attributeStrings.len() < element_count ||
                formattedText.len() <= min_length
            ) &&
            !formattedText.find(chr(10)) &&
            columnOffset + formattedText.len() <= settings.max_columns
        ) {
            return formattedText;
        }

        var elementNewLine = settings.lf & cfformat.indentTo(indent + 1, settings);
        var delimiter = (commaDelimited ? ',' : '') & elementNewLine;
        var formattedText = elementNewLine & attributeStrings.tolist(delimiter);
        formattedText &= settings.lf & cfformat.indentTo(indent, settings);
        return formattedText;
    }

    function printAttribute(
        cftokens,
        settings,
        indent,
        columnOffset,
        padding = false
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
        var spacer = padding ? ' ' : '';
        formattedText &= spacer & cftokens.next(false, true)[1] & spacer;

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

    function convertAttrTokensToDelimited(tokens) {
        var scope = {delimited_elements: [[]], type: 'function-call'};
        var firstAttributeSeen = false;
        for (var token in tokens) {
            if (isArray(token) && token[2].last().startswith('entity.other.attribute-name')) {
                if (firstAttributeSeen) {
                    scope.delimited_elements.append([]);
                }
                firstAttributeSeen = true;
            }
            scope.delimited_elements.last().append(token);
        }
        return scope;
    }

}
