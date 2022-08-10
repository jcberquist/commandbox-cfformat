component extends=tests.MetadataBaseSpec {

    function run() {
        describe('The metadata parser', function() {
            it('parses component method modifiers', function() {
                runTest(loadData('methodModifiers'));
            });
            it('parses component method parameters', function() {
                runTest(loadData('methodParameters'));
            });
            it('parses component method attributes', function() {
                runTest(loadData('methodAttributes'));
            });
            it('parses component method document comments', function() {
                runTest(loadData('methodDocBlock'));
            });
            it('parses component method param default values', function() {
                runTest(loadData('methodParamDefault'));
            });
            it('parses component method with no params and extra whitespace', function() {
                runTest(loadData('methodParamEmpty'));
            });
            it('parses tag component method attributes', function() {
                runTest(loadData('tagMethodAttributes'));
            });
            it('parses tag component method parameters', function() {
                runTest(loadData('tagMethodParameters'));
            });
        });
    }

}
