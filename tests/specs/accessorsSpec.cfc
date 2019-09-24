component extends=tests.FormatBaseSpec {

    function run() {
        describe('The accessors printer', function() {
            it('formats method calls', function() {
                runTests(loadData('methodCalls'));
            });
            it('uses the method call multiline setting', function() {
                runTests(loadData('methodCallsMultiline'));
            });
            it('formats method call chains with comments', function() {
                runTests(loadData('methodCallComments'));
            });
        });
    }

}
