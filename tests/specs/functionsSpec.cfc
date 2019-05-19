component extends=tests.FormatBaseSpec {

    function run() {
        describe('The function printer', function() {
            it('formats component methods', function() {
                runTests(loadData('function'));
            });
            it('preserves line comments', function() {
                runTests(loadData('functionArgsWithComments'));
            });
        });
    }

}
