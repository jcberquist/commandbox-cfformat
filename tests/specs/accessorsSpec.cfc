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
            it('formats accessors with comments', function() {
                runTests(loadData('accessorComments'));
            });
            it('formats accessors with tag in script names', function() {
                runTests(loadData('methodWithTagName'));
            });
            it('formats the safe navigation operator', function() {
                runTests(loadData('accessorsSafe'));
            });
        });
    }

}
