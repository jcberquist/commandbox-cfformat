component extends=testbox.system.BaseSpec {

    function run() {
    }

    function runTests(data, debugFormat = false) {
        var cfformat = new models.CFFormat('', expandPath('/data/'));
        data.settings.each(function(settings, index) {
            settings.append(cfformat.getDefaultSettings(), false);
            var formatted = cfformat.format(data.tokens, settings);
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
            'tokens': deserializeJSON(fileRead(tokenPath & '#testKey#/source.json')),
            'settings': deserializeJSON(fileRead(testPath & '#testKey#/settings.json')),
            'formatted': fileRead(testPath & '#testKey#/formatted.txt').reReplace('~\r?\n', '~', 'all').listToArray(
                '~'
            )
        };
        if (!data.formatted[1].trim().startsWith('<')) {
            data.tokens.elements = data.tokens.elements.slice(3);
        }
        return data;
    }

}
