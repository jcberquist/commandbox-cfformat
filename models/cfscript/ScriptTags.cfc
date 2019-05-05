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
            var attr_tokens = cfformat.cftokens(cftokens.next(false).elements);
        } else {
            // tag attr=val;
            var attr_tokens = cftokens.collectTo(argumentCollection = attrEnd);
        }

        // special cfproperty handling
        if (formattedText == 'property') {
            while (attr_tokens.hasNext() && !attr_tokens.peekScopeStartsWith('entity.other.attribute-name')) {
                formattedText &= ' ' & attr_tokens.next(false)[1];
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
            columnOffset + formattedText.len()
        );

        if (tagType == 'acf') {
            formattedText &= '(' & attributesTxt & ')';
        } else if (attributesTxt.len()) {
            formattedText &= ' ';
            if (attributesTxt.find(chr(10))) {
                formattedText &= attributesTxt
                    .trim()
                    .replace(chr(10), chr(10) & repeatString(' ', tagName.len() - 3), 'all');
            } else {
                formattedText &= attributesTxt.trim();
            }
        }

        if (cftokens.peekElement('block')) {
            formattedText &= ' ';
        } else if (!cftokens.peekText(';')) {
            formattedText &= settings.lf & cfformat.indentTo(indent, settings);
        }

        return formattedText;
    }

}
