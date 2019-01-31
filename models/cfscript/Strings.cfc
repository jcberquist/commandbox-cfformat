component {

    property cfformat;

    function init(cfformat) {
        variables.cfformat = cfformat;
        cfformat.cfscript.registerElement('string-single', this);
        cfformat.cfscript.registerElement('string-double', this);
        cfformat.cfscript.registerElement('string-single-tag', this);
        cfformat.cfscript.registerElement('string-double-tag', this);
        return this;
    }

    function print(
        cftokens,
        settings,
        indent,
        columnOffset
    ) {
        var element = cftokens.next(false);
        var quote = element.type.startswith('string-double') ? '"' : '''';

        if (element.type == 'string-double' && settings['strings.single_quote']) {
            quote = '''';
        }

        var formatted = '';
        for (var token in element.elements) {
            if (isArray(token)) {
                var fragment = token[1];
                if (element.type == 'string-double' && quote == '''') {
                    fragment = fragment.replace('''', '''''', 'all');
                }
                formatted &= fragment;
            } else {
                var template_expression = cfformat.cfscript
                    .print(cfformat.cftokens(token.elements), settings, indent)
                    .trim();
                formatted &= '##' & template_expression & '##';
            }
        }

        return quote & formatted & quote;
    }

}
