component {

    variables.attrNameScope = [
        ['entity.other.attribute-name.cfml'],
        ['entity.other.attribute-name.cfml', 'storage.modifier.extends.cfml']
    ];

    function init(metadata) {
        variables.metadata = arguments.metadata;
    }

    function parse(cftokens) {
        var meta = {};
        while (cftokens.hasNext()) {
            var attr = parseAttribute(cftokens);
            if (!isNull(attr)) {
                meta[attr.key] = attr.value;
            } else {
                break;
            }
        }
        return meta;
    }

    function parseAttribute(cftokens) {
        if (
            !cftokens.peekScopeStartsWith('entity.other.attribute-name', true) &&
            !cftokens.peekScopeStartsWith('storage.modifier.extends', true)
        )
            return;

        var attribute = {'key': cftokens.next(false, true)[1], 'value': ''};

        if (!cftokens.peekScopeStartsWith('punctuation.separator.key-value', true)) {
            return attribute;
        }

        // collect the '='
        cftokens.next(false, true);

        // stop at the next attribute name
        var val = [];

        while (
            cftokens.hasNext() &&
            !attrNameScope.some((scopes) => cftokens.peekScopes(scopes))
        ) {
            val.append(cftokens.next())
        }

        attribute.value = metadata.convertToText(val);

        return attribute;
    }

}
