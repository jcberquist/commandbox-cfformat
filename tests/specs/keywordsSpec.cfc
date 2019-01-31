component extends=tests.FormatBaseSpec {

    function run() {
        describe('The keyword printer', function() {
            it('formats keyswords', function() {
                runTests(loadData('keywords'));
            });
            it('tries to format keyswords followed by expression statements', function() {
                runTests(loadData('keywordStatement'));
            });
            it('formats the `new` keywords', function() {
                runTests(loadData('keywordNew'));
            });
            it('formats case statements', function() {
                runTests(loadData('switch'));
            });
            it('formats for loops', function() {
                runTests(loadData('forLoop'));
            });
        });
    }

}
