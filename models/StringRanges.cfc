component {

    variables.CFSCRIPT = [
        'line_comment',
        'doc_comment',
        'multiline_comment',
        'string_single',
        'string_double',
        'tag_comment',
        'tag_island'
    ];
    variables.CFTAGS = [
        'tag_comment',
        'cfscript_tag',
        'cfquery_tag',
        'cftag'
    ];
    variables.cfscriptStart = '(?=^\s*(?:/\*|//|import\b|(?:component|abstract\s*component|final\s*component|interface)(?:\s+|\{)))';
    variables.RangeDefinitions = {
        cfml: [
            '(?=.)',
            '\Z',
            ['cfscript', 'cftags'],
            'first'
        ],
        cfscript: [
            cfscriptStart,
            '(?=\Z)',
            CFSCRIPT,
            'first'
        ],
        cftags: ['(?=\S)', '(?=\Z)', CFTAGS, 'first'],
        cfscript_tag: [
            '<' & 'cfscript>',
            '</' & 'cfscript>',
            CFSCRIPT,
            'first'
        ],
        cfquery_tag: [
            '<' & 'cfquery\b',
            '</' & 'cfquery>',
            ['tag_comment'],
            'first'
        ],
        cftag: [
            '</?' & 'cf\w+',
            '>',
            ['string_single', 'string_double'],
            'first'
        ],
        escaped_double_quote: ['""', '(?=.)', [], 'first'],
        escaped_hash: ['####', '(?=.)', [], 'first'],
        escaped_single_quote: ['''''', '(?=.)', [], 'first'],
        hash: ['##', '##', CFSCRIPT, 'first'],
        line_comment: ['//', '\n', [], 'first'],
        doc_comment: ['/\*\*', '\*/', [], 'first'],
        multiline_comment: ['/\*', '\*/', [], 'first'],
        string_double: [
            '"',
            '"',
            ['escaped_hash', 'hash', 'escaped_double_quote'],
            'last'
        ],
        string_single: [
            '''',
            '''',
            ['escaped_hash', 'hash', 'escaped_single_quote'],
            'last'
        ],
        tag_comment: ['<!---', '--->', [], 'first'],
        tag_island: ['```', '```', CFTAGS, 'first']
    };

    function init() {
        variables.regex = initRegex();
        return this;
    }

    function walk(required string src) {
        var strRanges = [];
        var name = 'cfml';
        var pos = 0;
        var rangeToWalk = srcRange(name, pos);
        var currentRange = rangeToWalk;

        while (!isNull(currentRange)) {
            var matcher = regex[currentRange.name].end.matcher(src);

            if (!matcher.find(pos)) {
                currentRange.end = len(src);
                while (!isNull(currentRange.parent)) {
                    currentRange.parent.end = len(src);
                    currentRange = currentRange.parent;
                }
                break;
            }

            var name = groupName(regex[currentRange.name].names, matcher);
            pos = matcher.end();

            if (name == 'pop') {
                currentRange.end = pos;
                currentRange = !isNull(currentRange.parent) ? currentRange.parent : javacast('null', '');
            } else {
                var childRange = srcRange(name, matcher.start());
                childRange.parent = currentRange;
                currentRange.children.append(childRange);
                currentRange = childRange;

                if (
                    [
                        'string_single',
                        'string_double',
                        'line_comment',
                        'doc_comment',
                        'multiline_comment',
                        'tag_comment',
                        'cfquery_tag'
                    ].find(name)
                ) {
                    strRanges.append(currentRange);
                }
            }
        }

        return strRanges.map(function(r) {
            return {name: r.name, start: r.start, end: r.end};
        });
    }

    private function srcRange(name, start) {
        return {
            id: createUUID(),
            name: name,
            start: start,
            end: -1,
            children: [],
            parent: javacast('null', '')
        };
    }

    private function groupName(names, matcher) {
        for (var i = 1; i <= names.len(); i++) {
            if (!isNull(matcher.group(javacast('int', i)))) {
                return names[i];
            }
        }
    }

    private function initRegex() {
        // NOTE `34` is the bitOr of the flags DOTALL and CASE_INSENSITIVE
        var patternClass = createObject('java', 'java.util.regex.Pattern');

        var expandedRD = variables.RangeDefinitions.map(function(k, v) {
            return {
                start: v[1],
                end: v[2],
                child_ranges: v[3],
                pop: v[4]
            };
        });

        for (var name in expandedRD) {
            rd = expandedRD[name];
            regexMap[name] = {start: patternClass.compile(rd.start, 34)};

            var patterns = [];
            var names = [];

            for (var cr in rd.child_ranges) {
                var crd = expandedRD[cr];
                names.append(cr);
                patterns.append('(#crd.start#)');
            }

            if (rd.pop == 'first') {
                names.prepend('pop');
                patterns.prepend('(#rd.end#)');
            } else {
                names.append('pop');
                patterns.append('(#rd.end#)');
            }

            regexMap[name].end = patternClass.compile(patterns.toList('|'), 34);
            regexMap[name].names = names;
        }

        return regexMap;
    }

}
