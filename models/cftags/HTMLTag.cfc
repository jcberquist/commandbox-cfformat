component accessors="true" {

    function init(cfformat) {
        variables.cfformat = cfformat;
        cfformat.cftags.registerElement('htmltag', this);
        cfformat.cftags.registerElement('htmltag-closed', this);
        cfformat.cftags.registerElement('htmltag-selfclosed', this);
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
        var tagName = tagTokens.next(false)[1];

        if (settings['tags.lowercase']) {
            tagName = tagName.lCase();
        }

        var formattedText = element.type == 'htmltag-closed' ? '</' : '<';
        formattedText &= tagName;

        var attributesTxt = cfformat.cftags.htmlattributes.printAttributes(
            tagTokens,
            settings,
            indent,
            columnOffset + formattedText.len()
        );
        if (attributesTxt.len()) {
            if (!attributesTxt.startsWith(settings.lf)) {
                formattedText &= ' ';
            }
            formattedText &= attributesTxt;
        }

        formattedText &= element.type == 'htmltag-selfclosed' ? '/>' : '>';
        return formattedText;
    }

}
