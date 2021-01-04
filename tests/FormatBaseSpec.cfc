component extends=testbox.system.BaseSpec {

    function run() {
    }

    function runTests(data, debugFormat = false) {
        var cfformat = new models.CFFormat('', expandPath('/'));
        data.settings.each(function(settings, index) {
            try {
                var formatted = cfformat.format(data.tokens, cfformat.mergedSettings(settings));
            } catch (any e) {
                debug(e);
                rethrow;
            }
            if (debugFormat) {
                debug(serializeJSON(data.formatted[index]).replace(' ', '~', 'all'));
                debug(serializeJSON(formatted).replace(' ', '~', 'all'));
            }
            expect(formatted).toBeWithCase(data.formatted[index]);
        });
    }

    function loadData(testKey) {
        var testPath = expandPath('/tests/data/').replace('\', '/', 'all');
        var tokenPath = expandPath('/tests/json/').replace('\', '/', 'all');
        var data = {
            'tokens': deserializeJSON(fileRead(tokenPath & '#testKey#/source.json', 'utf-8')),
            'settings': deserializeJSON(fileRead(testPath & '#testKey#/settings.json', 'utf-8')),
            'formatted': fileRead(testPath & '#testKey#/formatted.txt', 'utf-8')
                .reReplace('~\r?\n', '~', 'all')
                .listToArray('~')
        };
        if (!data.formatted[1].trim().startsWith('<')) {
            data.tokens.elements = data.tokens.elements.slice(3);
        }
        return data;
    }

}
