component extends=tests.FormatBaseSpec {

    function run() {
        describe('cfformat', function() {
            it('can indent with tabs', function() {
                runTests(loadData('tabIndent'));
            });
            it('prints newlines after semicolons terminating statements', function() {
                runTests(loadData('semicolons'));
            });
        });
    }

}
