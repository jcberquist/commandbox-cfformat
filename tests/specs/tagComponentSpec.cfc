component extends=tests.FormatBaseSpec {

    function run() {
        describe('The tag printer', function() {
            it('formats and indents tag components', function() {
                runTests(loadData('tagComponent'));
            });
            it('formats cfquery', function() {
                runTests(loadData('cfquery'));
            });
            it('formats HTML in function bodies', function() {
                runTests(loadData('tagHTML'));
            });
        });
    }

}
