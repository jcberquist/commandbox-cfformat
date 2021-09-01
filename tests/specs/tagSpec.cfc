component extends=tests.FormatBaseSpec {

    function run() {
        describe('The cftag printer', function() {
            it('handles template expressions in unqoted attribute values', function() {
                runTests(loadData('attrTemplateExpression'));
            });
            it('correctly handles tag case', function() {
                runTests(loadData('tagCase'));
            });
            it('correctly handles a doctype declaration', function() {
                runTests(loadData('doctype'));
            });
            it('correctly indents the cfelse tag', function() {
                runTests(loadData('cfelse'));
            });
            it('correctly renders prefixed custom tags', function() {
                runTests(loadData('tagCustom'));
            });
            it('handles indents inside of HTML tags', function() {
                runTests(loadData('tagHTMLIndent'));
            });
            it('handles sequential template interpolations', function() {
                runTests(loadData('sequentialTemplateInterpolations'));
            });
        });
    }

}
