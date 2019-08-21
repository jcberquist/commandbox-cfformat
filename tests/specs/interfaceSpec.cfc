component extends=tests.FormatBaseSpec {

    function run() {
        describe('The component printer', function() {
            it('handles interfaces', function() {
                runTests(loadData('interface'));
            });
        });
    }

}
