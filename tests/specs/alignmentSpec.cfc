component extends=tests.FormatBaseSpec {

    function run() {
        describe('The alignment formatter', function() {
            it('aligns assignments', function() {
                runTests(loadData('alignAssignments'));
            });
        });
    }

}
