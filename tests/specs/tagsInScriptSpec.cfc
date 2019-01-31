component extends=tests.FormatBaseSpec {

    function run() {
        describe('The script tags printer', function() {
            it('formats tags in script', function() {
                runTests(loadData('tagsInScript'));
            });
            it('formats script component properties', function() {
                runTests(loadData('scriptProperty'));
            });
        });
    }

}
