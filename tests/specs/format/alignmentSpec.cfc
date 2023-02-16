component extends=tests.FormatBaseSpec {

    function run() {
        describe('The alignment formatter', function() {
            it('aligns assignments', function() {
                runTests(loadData('alignAssignments'));
            });
            it('correctly ignores the contents of strings and comments', function() {
                runTests(loadData('alignAssignmentsNoStrings'));
            });
            it('correctly ignores the contents of cfquery tags', function() {
                runTests(loadData('alignAssignmentsNoSQL'));
            });
            it('aligns assignments with brackets', function() {
                runTests(loadData('alignAssignmentsWithBrackets'));
            });
            it('aligns params with default assignments', function() {
                runTests(loadData('alignParamAssignments'));
            });
            it('aligns function parameters', function() {
                runTests(loadData('alignFunctionParams'));
            });
            it('aligns property attributes', function() {
                runTests(loadData('alignPropertyAttributes'));
            });
            it('aligns property attribute assignments', function() {
                runTests(loadData('alignPropertyAttributeAssignments'));
            });
            it('aligns param attributes', function() {
                runTests(loadData('alignParamAttributes'));
            });
            it('aligns doc comment param and throws descriptions', function() {
                runTests(loadData('alignDocComments'));
            });
            it('ignores doc comments where not every line starts with an asterisk', function() {
                runTests(loadData('alignDocCommentsIgnore'));
            });
        });
    }

}
