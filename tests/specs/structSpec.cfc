component extends=tests.FormatBaseSpec {

    function run() {
        describe('The struct printer', function() {
            it('formats empty structs', function() {
                runTests(loadData('structEmpty'));
            });
            it('spaces structs', function() {
                runTests(loadData('structSpacing'));
            });
            it('splits structs onto multiple lines', function() {
                runTests(loadData('structMultiline'));
            });
            it('keeps structs on one line no matter how many elements when they are short', function() {
                runTests(loadData('structMultilineShort'));
            });
            it('splits structs onto multiple lines with max col', function() {
                runTests(loadData('structMultilineMaxCol'));
            });
        });
    }

}
