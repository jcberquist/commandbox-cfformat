component accessors="true" {

    function init(cfformat) {
        variables.cfformat = cfformat;
        cfformat.cftags.registerElement('cftag', this);
        cfformat.cftags.registerElement('cftag-closed', this);
        cfformat.cftags.registerElement('cftag-selfclosed', this);
        return this;
    }

    function print(
        cftokens,
        settings,
        indent,
        columnOffset
    ) {
        var element = cftokens.next(false);
        var tagTokens = cfformat.cftokens(element.elements);
        var tagNameToken = tagTokens.next(false);
        var tagName = tagNameToken[1];

        if (tagNameToken[2].last() == 'entity.name.tag.custom.cfml') {
            while (tagTokens.peek()[2].find('entity.name.tag.custom.cfml')) {
                tagName &= tagTokens.next(false)[1];
            }
        }

        if (settings['tags.lowercase']) {
            tagName = tagName.lCase();
        }

        var formattedText = element.type == 'cftag-closed' ? '</' : '<';
        formattedText &= tagName;

        if (
            [
                'cfset',
                'cfreturn',
                'cfif',
                'cfelseif'
            ].findNoCase(tagName)
        ) {
            var scriptTxt = cfformat.cfscript
                .print(
                    tagTokens,
                    settings,
                    indent,
                    columnOffset + formattedText.len()
                )
                .trim();
            formattedText &= (element.type == 'cftag-closed' ? '' : ' ') & scriptTxt;
        } else {
            var attributesTxt = cfformat.cfscript.attributes.printAttributes(
                tagTokens,
                settings,
                indent,
                columnOffset + formattedText.len()
            );
            if (attributesTxt.len()) {
                if (!attributesTxt.startsWith(chr(10)) && !attributesTxt.startsWith(chr(13))) {
                    formattedText &= ' ';
                }
                formattedText &= attributesTxt;
            }
        }

        formattedText &= element.type == 'cftag-selfclosed' ? '/>' : '>';
        return formattedText;
    }

}
