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
        var quote = element.type.startswith('string-double') ? '"' : '''';
        var requiresConversion = false;

        for (q in quotes) {
            if (
                element.type == q.type &&
                settings[q.setting] == q.value
            ) {
                quote = q.quote;
                requiresConversion = true;
                break;
            }
        }

        var formatted = '';
        for (var token in element.elements) {
            if (isArray(token)) {
                var fragment = token[1];
                if (requiresConversion) {
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

        return quote & formatted & quote;
    }

}
