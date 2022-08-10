component extends=testbox.system.BaseSpec {

    function runTest(data, debugMetadata = false) {
        var cfformat = new models.CFFormat('', expandPath('/'));
        try {
            var metadata = cfformat.metadata.parse(data.tokens);
        } catch (any e) {
            debug(e);
            rethrow;
        }
        if (debugMetadata) {
            debug(metadata);
            debug(data.metadata);
        }
        expect(metadata).toBe(data.metadata);
    }

    function loadData(testKey) {
        var tokenPath = expandPath('/tests/json/metadata/').replace('\', '/', 'all');
        var testPath = expandPath('/tests/data/metadata/').replace('\', '/', 'all');
        var data = {
            'tokens': deserializeJSON(fileRead(tokenPath & '#testKey#/source.json', 'utf-8')),
            'metadata': deserializeJSON(fileRead(testPath & '#testKey#/metadata.json', 'utf-8'))
        };
        return data;
    }

}
