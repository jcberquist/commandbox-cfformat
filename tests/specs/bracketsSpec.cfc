component extends=tests.FormatBaseSpec {

    function run() {
        describe('The bracket printer', function() {
            it('formats brackets', function() {
                runTests(loadData('brackets'));
            });
        });
    }

}
