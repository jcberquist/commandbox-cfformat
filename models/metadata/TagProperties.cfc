component {

    function init(metadata) {
        variables.metadata = arguments.metadata;
    }

    function parse(tag) {
        var meta = {};

        var attributeTokens = variables.metadata.cftokens(tag.elements);
        // move past the `cfproperty` token
        attributeTokens.next();

        meta.append(variables.metadata.attributes.parse(attributeTokens));

        return meta;
    }

}
