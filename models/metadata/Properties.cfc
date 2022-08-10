component {

    function init(metadata) {
        variables.metadata = arguments.metadata;
    }

    function parse(cftokens, docComment) {
        var meta = {};
        meta.append(docComment);

        while (cftokens.hasNext()) {
            if (cftokens.peekScopeStartsWith('entity.other.attribute-name', true)) {
                // reached the attributes
                break;
            }

            var token = cftokens.next();

            if (isArray(token)) {
                if (token[2].last().startswith('meta.tag.property.name.cfml')) {
                    meta['name'] = token[1];
                }
                if (token[2].last().startswith('storage.type.cfml')) {
                    meta['type'] = token[1];
                }
            }
        }
        meta.append(metadata.attributes.parse(cftokens));
        return meta;
    }

}
