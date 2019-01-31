component extends=tests.FormatBaseSpec {

    function run() {
        describe('The accessors printer', function() {
            it('formats method calls', function() {
                runTests(loadData('methodCalls'));
            });
        });
    }

}
