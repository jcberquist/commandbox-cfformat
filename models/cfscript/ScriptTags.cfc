component {

    property cfformat;

    variables.attrStart = {scopes: [['entity.other.attribute-name']], elements: []};
    variables.attrEnd = {scopes: [['punctuation.terminator.statement']], elements: ['block']};

    function init(cfformat) {
        variables.cfformat = cfformat;
        cfformat.cfscript.register('entity.name.tag.script', this);
        return this;
    }

    function print(
        cftokens,
        settings,
        indent,
        columnOffset
    ) {
        var token = cftokens.next(false);
        var tagName = token[1];
        var formattedText = tagName;
        var tagType = token[2][token[2].len() - 1] == 'meta.tag.script.cf.cfml' ? 'acf' : 'lucee';

        if (tagType == 'acf') {
            // cftag();
            // next should be tag-attributes element
            formattedText &= printACFScriptAttributes(
                cftokens,
                settings,
                indent,
                columnOffset + tagName.len()
            );
        } else {
            // check to see if this tag name is followed by accessor
            if (cftokens.peekScopeStartsWith('punctuation.accessor.cfml', true)) {
                // this is actually not a tag in script
                return formattedText;
            }

            // tag attr=val;
            var attr_tokens = cftokens.collectTo(argumentCollection = attrEnd);
            var tagSetting = '';

            // special cfproperty handling
            if (formattedText == 'property') {
                tagSetting = 'property';
                while (attr_tokens.hasNext() && !attr_tokens.peekScopeStartsWith('entity.other.attribute-name', true)) {
                    formattedText &= ' ' & attr_tokens.next(false, false)[1];
                }
            }

            // special cfparam handling
            if (formattedText == 'param') {
                var preAttrTokens = attr_tokens.collectTo(argumentCollection = attrStart);
                var preAttrTxt = cfformat.cfscript.print(preAttrTokens, settings, indent).trim();
                if (preAttrTxt.len()) formattedText &= ' ' & preAttrTxt;
            }

            var attributesTxt = cfformat.cfscript.attributes.printAttributes(
                attr_tokens,
                settings,
                indent,
                columnOffset + formattedText.len(),
                nullValue(),
                tagType == 'acf',
                tagSetting
            );

            if (attributesTxt.len()) {
                if (attributesTxt.find(chr(10))) {
                    formattedText &= attributesTxt.rtrim();
                } else {
                    formattedText &= ' ' & attributesTxt.trim();
                }
            }
        }

        if (cftokens.peekElement('block')) {
            formattedText &= ' ';
        } else if (!cftokens.peekText(';')) {
            formattedText &= settings.lf & cfformat.indentTo(indent, settings);
        }

        return formattedText;
    }

    function printACFScriptAttributes(
        cftokens,
        settings,
        indent,
        columnOffset
    ) {
        var attrTokens = cftokens.next(false).elements;
        var delimited = cfformat.cfscript.attributes.convertAttrTokensToDelimited(attrTokens);

        var printedElements = cfformat.delimited.printElements(delimited, settings, indent);

        if (printedElements.printed.len() == 1 && printedElements.printed[1].trim() == '') {
            return settings['function_call.empty_padding'] ? '( )' : '()';
        }

        var spacer = settings['function_call.padding'] ? ' ' : '';
        var delimiter = ', ';

        if (printedElements.endingComments.isEmpty() && printedElements.afterCommaComments.isEmpty()) {
            var formattedText = '(' & spacer & printedElements.printed.tolist(delimiter) & spacer & ')';
            if (
                (
                    printedElements.printed.len() < settings['function_call.multiline.element_count'] ||
                    formattedText.len() <= settings['function_call.multiline.min_length']
                ) &&
                !formattedText.find(chr(10)) &&
                columnOffset + formattedText.len() <= settings.max_columns
            ) {
                return formattedText;
            }
        }

        var formattedText = '(';
        formattedText &= cfformat.delimited.joinElements(
            'function_call',
            printedElements,
            settings,
            indent
        );
        formattedText &= settings.lf & cfformat.indentTo(indent, settings) & ')';
        return formattedText;
    }

}
