component extends=tests.FormatBaseSpec {

    function run() {
        describe('The group printer', function() {
            it('handles comments in the group', function() {
                runTests(loadData('groupWithComment'));
            });
        });
    }

}
