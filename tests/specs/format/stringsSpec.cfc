component extends=tests.FormatBaseSpec {

    function run() {
        describe('The string printer', function() {
            it('defaults to single quote strings', function() {
                runTests(loadData('strings'));
            });
            it('can avoid converting strings with nested quotes', function() {
                runTests(loadData('stringsNestedQuotes'));
            });
        });
    }

}
