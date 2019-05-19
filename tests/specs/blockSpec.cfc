component extends=tests.FormatBaseSpec {

    function run() {
        describe('The block printer', function() {
            it('ensures a newline after the block', function() {
                runTests(loadData('blocks'));
            });
        });
    }

}
