component extends=tests.FormatBaseSpec {

    function run() {
        describe('The block printer', function() {
            it('handles newlines before the block', function() {
                runTests(loadData('blockAfterNewline'));
            });
            it('ensures a newline after the block', function() {
                runTests(loadData('blocks'));
            });
        });
    }

}
