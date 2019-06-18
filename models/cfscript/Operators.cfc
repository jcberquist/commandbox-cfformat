component {

    property cfformat;

    variables.binaryOperators = [
        'keyword.operator.assignment.binary.cfml',
        'keyword.operator.assignment.augmented.binary.cfml',
        'keyword.operator.arithmetic.binary.cfml',
        'keyword.operator.relational.binary.cfml',
        'keyword.operator.decision.binary.cfml',
        'keyword.operator.comparison.binary.cfml',
        'keyword.operator.concat.binary.cfml'
    ];

    variables.binaryOperatorsSpaced = ['keyword.operator.logical.binary.cfml', 'keyword.operator.binary.cfml'];

    function init(cfformat) {
        variables.cfformat = cfformat;
        cfformat.cfscript.register('keyword.operator.', this);
        return this;
    }

    function print(cftokens, settings, indent, offset) {
        if (!cftokens.peekScopeStartsWith('keyword.operator.')) return;

        for (var scope in binaryOperators) {
            if (cftokens.peekScopes([scope])) {
                var leftSpacer = settings['binary_operators.padding'] ? ' ' : '';
                var rightSpacer = settings['binary_operators.padding'] ? ' ' : '';
				if( find( 'assignment', scope ) && settings['assignment_operators.compact'] ) {
					leftSpacer = '';
				}
                var token = cftokens.next(whitespace = false);
                cftokens.consumeWhiteSpace();
                return leftSpacer & token[1] & (cftokens.peekNewline() ? '' : rightSpacer);
            }
        }

        for (var scope in binaryOperatorsSpaced) {
            if (cftokens.peekScopes([scope])) {
                var spacer = ' ';
                var token = cftokens.next(whitespace = false);
                cftokens.consumeWhiteSpace();
                return spacer & token[1] & (cftokens.peekNewline() ? '' : spacer);
            }
        }

        if (cftokens.peekScopeStartsWith('keyword.operator.ternary')) {
            var token = cftokens.next(whitespace = false);
            var operator = token[1];
            cftokens.consumeWhiteSpace(true);
            // check for elvis operator
            if (operator == '?' && cftokens.peekText(':')) {
                cftokens.next(whitespace = false);
                cftokens.consumeWhiteSpace(true);
                operator = '?:';
            }
            var spacer = settings['binary_operators.padding'] ? ' ' : '';
            return spacer & operator & spacer;
        }

        if (cftokens.peekScopeStartsWith('keyword.operator.word.new')) {
            var token = cftokens.next(whitespace = false);
            cftokens.consumeWhiteSpace(true);
            return 'new ';
        }

        if (
            cftokens.peekScopeStartsWith('keyword.operator.arithmetic.prefix.') ||
            cftokens.peekScopeStartsWith('keyword.operator.logical.prefix.')
        ) {
            var token = cftokens.next(whitespace = false);
            cftokens.consumeWhiteSpace(true);
            return token[1] & (token[1] == 'not' ? ' ' : '');
        }

        if (cftokens.peekScopeStartsWith('keyword.operator.arithmetic.postfix.')) {
            var token = cftokens.next(whitespace = false);
            return token[1];
        }
    }

}
