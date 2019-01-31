component extends=tests.FormatBaseSpec {

    function run() {
        describe('The string printer', function() {
            it('defaults to single quote strings', function() {
                runTests(loadData('strings'));
            });
        });
    }

}
