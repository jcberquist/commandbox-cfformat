component {

    function init(metadata) {
        variables.metadata = arguments.metadata;
    }

    function parse(docblock) {
        var meta = {};
        var cftokens = variables.metadata.cftokens(docblock.elements);
        var state = 'start';
        var line = {key: 'hint', value: ''};
        while (cftokens.hasNext()) {
            var token = cftokens.next();
            if (isArray(token)) {
                if (token[1].endswith(chr(10))) {
                    if (len(line.value)) {
                        if (!meta.keyExists(line.key)) {
                            meta[line.key] = line.value.trim();
                        } else {
                            meta[line.key] &= token[1] & line.value.trim();
                        }
                    }
                    state = 'start';
                    line = {key: 'hint', value: ''};
                } else if (state == 'start' && token[1].trim() == '*') {
                    state = 'afterStar';
                } else if (
                    ['start', 'afterStar'].find(state) &&
                    token[2].last() == 'punctuation.definition.keyword.cfml'
                ) {
                    state = 'keyword';
                } else if (
                    state == 'keyword' &&
                    token[2].last() == 'keyword.other.documentation.cfml'
                ) {
                    line.key = token[1];
                    state = 'end';
                } else {
                    state = 'end';
                    line.value &= token[1];
                }
            }
        }
        return meta;
    }

}
