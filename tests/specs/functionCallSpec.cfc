component extends=tests.FormatBaseSpec {

    function run() {
        describe('The function call printer', function() {
            it('formats function parameters', function() {
                runTests(loadData('functionCall'));
            });
            it('special cases anonymous function parameters', function() {
                runTests(loadData('functionCallAnonFunction'));
            });
            it('special cases single struct or array parameters', function() {
                runTests(loadData('functionCallStructOrArray'));
            });
            it('preserves line comments', function() {
                runTests(loadData('functionCallWithComments'));
            });
            it('formats the casing of built in function calls', function() {
                runTests(loadData('functionCallBuiltinCasing'));
            });
            it('can format the casing of user defined function calls', function() {
                runTests(loadData('functionCallUdCasing'));
            });
        });
    }

}
