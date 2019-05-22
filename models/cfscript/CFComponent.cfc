component {

    property cfformat;

    variables.componentStart = ['meta.class.declaration.cfml', '*'];
    variables.attrEnd = {scopes: [], elements: ['block']};

    function init(cfformat) {
        variables.cfformat = cfformat;
        cfformat.cfscript.register('storage.', this);
        return this;
    }

    function print(
        cftokens,
        settings,
        indent,
        columnOffset
    ) {
        if (!cftokens.peekScopes(componentStart)) return;

        var tokens = [];
        do {
            tokens.append(cftokens.next()[1]);
        } while (tokens.last() != 'component');

        var formattedText = tokens.toList(' ');

        // handle tag metadata
        var attributesTxt = cfformat.cfscript.attributes.printAttributes(
            cftokens,
            settings,
            indent,
            columnOffset + formattedText.len(),
            attrEnd
        );
        if (attributesTxt.len()) {
            attributesTxt = ' ' & attributesTxt;
            formattedText &= attributesTxt;
        }

        cftokens.consumeWhitespace(true);

        if (!attributesTxt.find(chr(10))) {
            formattedText = formattedText & ' ';
        }

        var blockTxt = cfformat.cfscript.blocks.print(cftokens, settings, indent).rtrim();
        blockTxt = blockTxt.insert(settings.lf, 1);
        blockTxt = blockTxt.insert(settings.lf, blockTxt.len() - 1);
        formattedText &= blockTxt & settings.lf;

        return formattedText;
    }

}
