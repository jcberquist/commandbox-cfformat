component accessors="true" {

    function init(cfformat) {
        variables.cfformat = cfformat;
        cfformat.cftags.registerElement('doctype', this);
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
        var tagStart = '<';
        var tagName = tagTokens.next(false)[1];

        if (element.type == 'doctype') {
            tagStart = '<!';
        } else {
            if (element.type == 'htmltag-closed') {
                tagStart = '</';
            }
            if (settings['tags.lowercase']) {
                tagName = tagName.lCase();
            }
        }

        var formattedText = tagStart & tagName;

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
