component extends=tests.FormatBaseSpec {

    function run() {
        describe('The operator printer', function() {
            it('formats binary operators', function() {
                runTests(loadData('binaryOperators'));
            });

            it('formats binary operators over multiple lines', function() {
                runTests(loadData('binaryOperatorsMultiline'));
            });

            it('formats ternary operators', function() {
                runTests(loadData('ternaryOperator'));
            });

            it('formats prefix operators', function() {
                runTests(loadData('prefixOperators'));
            });

            it('formats postfix operators', function() {
                runTests(loadData('postfixOperators'));
            });

            it('formats word operators', function() {
                runTests(loadData('wordOperators'), true);
            });
        });
    }

}
