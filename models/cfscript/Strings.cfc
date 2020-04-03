component {

    property cfformat;

    variables.quotes = [
        {
            type: 'string-double',
            setting: 'strings.quote',
            value: 'single',
            quote: ''''
        },
        {
            type: 'string-single',
            setting: 'strings.quote',
            value: 'double',
            quote: '"'
        },
        {
            type: 'string-double-tag',
            setting: 'strings.attributes.quote',
            value: 'single',
            quote: ''''
        },
        {
            type: 'string-single-tag',
            setting: 'strings.attributes.quote',
            value: 'double',
            quote: '"'
        }
    ];

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
        var currentQuote = element.type.startswith('string-double') ? '"' : '''';
        var targetQuote = currentQuote;
        var elementContainsQuotes = element.elements.some((t) => isArray(t) && t[1].refind('[''"]'));

        if (!elementContainsQuotes || settings['strings.convertNestedQuotes']) {
            for (var q in quotes) {
                if (
                    element.type == q.type &&
                    settings[q.setting] == q.value
                ) {
                    targetQuote = q.quote;
                    break;
                }
            }
        }

        var formatted = '';
        for (var token in element.elements) {
            if (isArray(token)) {
                var fragment = token[1];
                if (targetQuote != currentQuote) {
                    if (element.type.startswith('string-double')) {
                        fragment = fragment.replace('''', '''''', 'all').replace('""', '"', 'all');
                    } else if (element.type.startswith('string-single')) {
                        fragment = fragment.replace('"', '""', 'all').replace('''''', '''', 'all');
                    }
                }
                formatted &= fragment;
            } else {
                var template_expression = cfformat.cfscript
                    .print(cfformat.cftokens(token.elements), settings, indent)
                    .trim();
                formatted &= '##' & template_expression & '##';
            }
        }

        return targetQuote & formatted & targetQuote;
    }

}
