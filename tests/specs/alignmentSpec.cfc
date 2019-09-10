component extends=tests.FormatBaseSpec {

    function run() {
        describe('The alignment formatter', function() {
            it('aligns assignments', function() {
                runTests(loadData('alignAssignments'));
            });
            it('aligns assignments with brackets', function() {
                runTests(loadData('alignAssignmentsWithBrackets'));
            });
            it('aligns function parameters', function() {
                runTests(loadData('alignFunctionParams'));
            });
        });
    }

}
