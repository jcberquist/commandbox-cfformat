component {

    property cfformat;

    function init(cfformat) {
        variables.cfformat = cfformat;
        cfformat.cftags.registerElement('template-expression', this);
        cfformat.cfscript.registerElement('template-expression', this);
        return this;
    }

    function print(
        cftokens,
        settings,
        indent,
        columnOffset
    ) {
        var element = cftokens.next(false);

        var template_expression = cfformat.cfscript.print(cfformat.cftokens(element.elements), settings, indent).trim();
        return '##' & template_expression & '##';
    }

}
