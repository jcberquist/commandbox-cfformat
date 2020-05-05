component extends=tests.FormatBaseSpec {

    function run() {
        describe('The script tags printer', function() {
            it('formats tags in script', function() {
                runTests(loadData('tagsInScript'));
            });
            it('formats ACF style tags in script', function() {
                runTests(loadData('cfTagsInScript'));
            });
            it('formats script component properties', function() {
                runTests(loadData('scriptProperty'));
            });
            it('it respects the min_length setting for property attributes', function() {
                runTests(loadData('scriptPropertyShort'));
            });
            it('formats script params', function() {
                runTests(loadData('scriptParam'));
            });
        });
    }

}
