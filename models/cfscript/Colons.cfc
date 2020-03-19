component {

    property cfformat;

    function init(cfformat) {
        variables.cfformat = cfformat;
        cfformat.cfscript.register('punctuation.separator.key-value.', this);
        return this;
    }

    function print(
        cftokens,
        settings,
        indent,
        columnOffset
    ) {
        if (cftokens.peekScopeStartsWith('punctuation.separator.key-value.cfml') && cftokens.peek()[1] == ':') {
            var token = cftokens.next(whitespace = false);
            cftokens.consumeWhiteSpace(true);
            return ': ';
        }
    }

}
