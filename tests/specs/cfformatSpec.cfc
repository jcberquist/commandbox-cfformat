component extends=tests.FormatBaseSpec {

    function run() {
        describe('cfformat', function() {
            it('can indent with tabs', function() {
                runTests(loadData('tabIndent'));
            });
            it('prints newlines after semicolons terminating statements', function() {
                runTests(loadData('semicolons'));
            });
            it('ignores code inside ignore comments', function() {
                runTests(loadData('cfformatIgnore'), true);
            });
            it('ignores code inside tag ignore comments', function() {
                runTests(loadData('cfformatIgnoreTags'), true);
            });
        });
    }

}
