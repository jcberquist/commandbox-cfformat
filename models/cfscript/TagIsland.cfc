component {

    property cfformat;

    function init(cfformat) {
        variables.cfformat = cfformat;
        cfformat.cfscript.registerElement('tag-island', this);
        return this;
    }

    function print(
        cftokens,
        settings,
        indent,
        columnOffset
    ) {
        var element = cftokens.next(false, true);

        var tokens = cfformat.postProcess(element);

        var tagIsland = cfformat.cftags.print(cfformat.cftokens(tokens.elements), settings, indent).trim();

        var newlineIndent = settings.lf & cfformat.indentTo(indent, settings);

        var formatted = '```';
        if (tagIsland.len()) {
            formatted &= newlineIndent;
            formatted &= tagIsland;
        }
        formatted &= newlineIndent & '```' & settings.lf;

        if (cftokens.peekNewline()) {
            cftokens.next(false);
        }

        cftokens.consumeWhitespace(false);

        if (!cftokens.peekNewline()) {
            formatted &= cfformat.indentTo(indent, settings);
        }

        return formatted;
    }

}
