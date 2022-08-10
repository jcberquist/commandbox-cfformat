component extends=tests.MetadataBaseSpec {

    function run() {
        describe('The metadata parser', function() {
            it('parses component properties', function() {
                runTest(loadData('properties'));
            });
            it('parses component property doc comments', function() {
                runTest(loadData('propertyDocBlock'));
            });
            it('parses tag component properties', function() {
                runTest(loadData('tagProperties'));
            });
        });
    }

}
