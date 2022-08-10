component {

    function init(metadata) {
        variables.metadata = arguments.metadata;
    }

    function parse(tag) {
        var meta = {'parameters': []};

        var attributeTokens = variables.metadata.cftokens(tag.starttag.elements);
        // move past the `cffunction` token
        attributeTokens.next();
        meta.append(variables.metadata.attributes.parse(attributeTokens));

        var cftokens = variables.metadata.cftokens(tag.elements);

        while (cftokens.hasNext()) {
            var token = cftokens.next();

            if (isStruct(token) && token.type == 'cftag' && token.tagName == 'cfargument') {
                var attributeTokens = variables.metadata.cftokens(token.elements);
                // move past the `cfargument` token
                attributeTokens.next();
                meta.parameters.append(variables.metadata.attributes.parse(attributeTokens));
            }
        }

        return meta;
    }

}
