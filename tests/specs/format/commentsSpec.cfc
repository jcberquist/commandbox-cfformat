component extends=tests.FormatBaseSpec {

    function run() {
        describe('The comment printer', function() {
            it('formats doc comments', function() {
                runTests(loadData('commentDoc'));
            });
            it('formats block comments', function() {
                runTests(loadData('commentBlock'));
            });
            it('formats line comments', function() {
                runTests(loadData('commentLine'));
            });
            it('formats tag comments', function() {
                runTests(loadData('commentTag'));
            });
            it('keeps specialized block comments on a single line', function() {
                runTests(loadData('commentSingleline'));
            });
            it('formats empty line comments', function() {
                runTests(loadData('commentEmpty'));
            });
        });
    }

}
