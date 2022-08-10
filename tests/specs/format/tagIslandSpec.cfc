component extends=tests.FormatBaseSpec {

    function run() {
        describe('The cfscript printer', function() {
            it('handles tag islands', function() {
                runTests(loadData('tagisland'));
            });
        });
    }

}
