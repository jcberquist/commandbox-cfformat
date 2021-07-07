component extends=tests.FormatBaseSpec {

    function run() {
        describe('The function printer', function() {
            it('formats component methods', function() {
                runTests(loadData('function'));
            });
            it('preserves line comments', function() {
                runTests(loadData('functionArgsWithComments'));
            });
            it('formats anonymous functions', function() {
                runTests(loadData('functionAnon'));
            });
            it('handles function params typed as components', function() {
                runTests(loadData('functionParamTyped'));
            });
            it('formats function metadata attributes', function() {
                runTests(loadData('functionMetadata'));
            });
            it('formats function keyword and name spacing to the params', function() {
                runTests(loadData('functionSpacingToGroup'));
            });
            it('formats arrow functions with a single parameter and no parentheses', function() {
                runTests(loadData('functionArrowNoParens'));
            });
            it('formats arrow functions with trailing whitespace', function() {
                runTests(loadData('functionArrowTrailingWhitespace'));
            });
        });
    }

}
