component extends=tests.FormatBaseSpec {

    function run() {
        describe('The keyword printer', function() {
            it('formats keyswords', function() {
                runTests(loadData('keywords'));
            });
            it('tries to format keyswords followed by expression statements', function() {
                runTests(loadData('keywordStatement'));
            });
            it('formats the `new` keyword', function() {
                runTests(loadData('keywordNew'));
            });
            it('formats the `throw` keyword', function() {
                runTests(loadData('keywordThrow'));
            });
            it('formats the `include` keyword', function() {
                runTests(loadData('keywordInclude'));
            });
            it('formats case statements', function() {
                runTests(loadData('switch'));
            });
            it('formats for loops', function() {
                runTests(loadData('forLoop'));
            });
            it('formats expression statements', function() {
                runTests(loadData('keywordExprStatement'));
            });
        });
    }

}
