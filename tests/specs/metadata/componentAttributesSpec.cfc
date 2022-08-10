component extends=tests.MetadataBaseSpec {

    function run() {
        describe('The metadata parser', function() {
            it('parses component attributes', function() {
                runTest(loadData('attributes'));
            });
            it('parses a component docblock', function() {
                runTest(loadData('docBlock'));
            });
            it('parses tag component attributes', function() {
                runTest(loadData('tagAttributes'));
            });
        });
    }

}
