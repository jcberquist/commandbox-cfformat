component extends=tests.FormatBaseSpec {

    function run() {
        describe('The array printer', function() {
            it('formats empty arrays', function() {
                runTests(loadData('arrayEmpty'));
            });
            it('spaces arrays', function() {
                runTests(loadData('arraySpacing'));
            });
            it('splits arrays onto multiple lines', function() {
                runTests(loadData('arrayMultiline'));
            });
            it('keeps arrays on one line no matter how many elements when they are short', function() {
                runTests(loadData('arrayMultilineShort'));
            });
            it('splits arrays onto multiple lines with max col', function() {
                runTests(loadData('arrayMultilineMaxCol'));
            });
            it('preserves line comments', function() {
                runTests(loadData('arrayWithComments'));
            });
        });
    }

}
