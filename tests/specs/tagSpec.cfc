component extends=tests.FormatBaseSpec {

    function run() {
        describe('The cftag printer', function() {
            it('handles template expressions in unqoted attribute values', function() {
                runTests(loadData('attrTemplateExpression'));
            });
            it('correctly ignores tag case', function() {
                runTests(loadData('tagCase'));
            });
            it('correctly indents the cfelse tag', function() {
                runTests(loadData('cfelse'));
            });
        });
    }

}
