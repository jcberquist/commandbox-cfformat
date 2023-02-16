component {

    property cfformat;

    variables.componentStart = ['meta.class.declaration.cfml', '*'];
    variables.interfaceStart = ['meta.interface.declaration.cfml', '*'];
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
        if (
            !cftokens.peekScopes(componentStart) &&
            !cftokens.peekScopes(interfaceStart)
        ) {
            return;
        }

        var tokens = [];
        do {
            var nextToken = cftokens.next()[1];
            if (nextToken.trim().len()) {
                tokens.append(nextToken);
            }
        } while (tokens.last() != 'component' && tokens.last() != 'interface');

        var formattedText = tokens.toList(' ');

        // handle tag metadata
        var attributesTxt = cfformat.cfscript.attributes.printAttributes(
            cftokens,
            settings,
            indent,
            columnOffset + formattedText.len(),
            attrEnd,
            false,
            'metadata'
        );
        if (attributesTxt.len()) {
            if (!attributesTxt.find(chr(10))) {
                attributesTxt = ' ' & attributesTxt;
            }
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
