component extends=tests.FormatBaseSpec {

    function run() {
        describe('cfformat indenting', function() {
            it('can be done with tabs', function() {
                runTests(loadData('tabIndent'));
            });
        });
    }

}
