component accessors="true" {

    variables.identifier = '[A-Za-z0-9$._]+';

    variables.assignmentRegex = [
        '^([ \t,]*)', // leading indentation
        '(', // three possibilities
        '(?:var\s*)?(?i:"[^"]*"|''[^'']*''|#identifier#)(?:\[[^\]]+\])*', // variable assignment
        '|',
        '(?i:param[ \t]+)?#identifier#(?:[ \t]+#identifier#)?', // params
        '|',
        '(?i:required[ \t]+)?#identifier#(?:[ \t]+#identifier#)?', // function parameters
        ')',
        '([ \t]*[:=](?!=)[^\r\n]*)\r?\n'
    ];
    variables.commentRegex = '^[ \t]*//[^\r\n]*\r?\n';
    variables.propertiesRegex = [
        '^([ \t,]*)', // leading indentation
        '(?i:property)', // tag name
        '\s+',
        '((?:\s*',
        identifier, // attribute name
        '(?![A-Za-z0-9$._])', // boundary to prevent backtracking
        '(?:',
        '\s*=\s*',
        '(?i:"[^"]*"|''[^'']*''|#identifier#)', // attribute value
        ')?', // attribute value is optional
        ')*)',
        ';?\r?\n'
    ];
    variables.attributeRegex = [
        '(#identifier#)', // attribute name
        '(?![A-Za-z0-9$._])', // boundary to prevent backtracking
        '(?:',
        '\s*=\s*',
        '(?:"[^"]*"|''[^'']*''|#identifier#)', // attribute value
        ')?' // attribute value is optional
    ];
    variables.docParamRegex = [
        '^([ \t]*\*\s*)', // leading indentation and *
        '(?!(?i:@throws|@return))', // not @throws or @return
        '(@#identifier#)', // param name
        '([^\r\n]*)\r?\n' // param description (rest of the line)
    ];
    variables.docThrowsRegex = [
        '^([ \t]*\*\s*)', // leading indentation and *
        '(?i:(@throws\s+#identifier#))',
        '([^\r\n]*)\r?\n' // throws description (rest of the line)
    ];

    function init() {
        var patternClass = createObject('java', 'java.util.regex.Pattern');
        variables.stringRanges = new StringRanges();
        variables.assignmentPattern = patternClass.compile(assignmentRegex.toList(''), 8);
        variables.commentPattern = patternClass.compile(commentRegex, 8);
        variables.propertiesPattern = patternClass.compile(propertiesRegex.toList(''), 8);
        variables.paramsPattern = patternClass.compile(propertiesRegex.toList('').replace('property', 'param'), 8);
        variables.attributePattern = patternClass.compile(attributeRegex.toList(''), 8);
        variables.docParamPattern = patternClass.compile(docParamRegex.toList(''), 8);
        variables.docThrowsPattern = patternClass.compile(docThrowsRegex.toList(''), 8);

        return this;
    }

    string function alignAssignments(required string src) {
        var aMatcher = assignmentPattern.matcher(src);
        var cMatcher = commentPattern.matcher(src);
        var index = 0;
        var strRanges = {index: 1, ranges: stringRanges.walk(src)};
        var replacements = [];

        while (aMatcher.find(index)) {
            index = aMatcher.end();

            if (inStringRange(aMatcher.start(3), strRanges)) {
                continue;
            }

            var group = [aMatcher.toMatchResult()];
            var indent = aMatcher.group(1);

            while (true) {
                aMatcher.region(index, len(src));
                if (aMatcher.lookingAt()) {
                    if (
                        !inStringRange(aMatcher.start(3), strRanges) &&
                        len(indent) == len(aMatcher.group(1))
                    ) {
                        group.append(aMatcher.toMatchResult());
                        index = aMatcher.end();
                        continue;
                    }
                } else {
                    cMatcher.region(index, len(src));
                    if (cMatcher.lookingAt()) {
                        index = cMatcher.end();
                        continue;
                    }
                }

                if (arrayLen(group) > 1) {
                    replacements.append(parseAssignmentGroup(group), true);
                }
                break;
            }
        }

        for (var replacement in replacements.reverse()) {
            src = src.substring(0, replacement.start) & replacement.line & src.substring(replacement.end);
        }

        return src;
    }

    string function alignAttributes(required string src, required string type) {
        var aMatcher = type == 'properties' ? propertiesPattern.matcher(src) : paramsPattern.matcher(src);
        var cMatcher = commentPattern.matcher(src);
        var index = 0;
        var strRanges = {index: 1, ranges: stringRanges.walk(src)};
        var replacements = [];

        while (aMatcher.find(index)) {
            index = aMatcher.end();

            if (inStringRange(aMatcher.start(2), strRanges)) {
                continue;
            }

            var group = [parseAttributes(aMatcher)];
            var indent = aMatcher.group(1);

            while (true) {
                aMatcher.region(index, len(src));
                if (aMatcher.lookingAt()) {
                    if (!inStringRange(aMatcher.start(2), strRanges)) {
                        var parsed = parseAttributes(aMatcher);
                        if (
                            len(indent) == len(aMatcher.group(1)) &&
                            group.last().names == parsed.names
                        ) {
                            group.append(parsed);
                            index = aMatcher.end();
                            continue;
                        }
                    }
                } else {
                    cMatcher.region(index, len(src));
                    if (cMatcher.lookingAt()) {
                        index = cMatcher.end();
                        continue;
                    }
                }

                if (arrayLen(group) > 1) {
                    replacements.append(parseAttributeGroup(group), true);
                }
                break;
            }
        }

        for (var replacement in replacements.reverse()) {
            src = src.substring(0, replacement.start) & replacement.line & src.substring(replacement.end);
        }

        return src;
    }

    string function alignDocComments(required string src) {
        var replacements = [];
        var ranges = stringRanges.walk(src);

        for (var matcher in [docParamPattern.matcher(src), docThrowsPattern.matcher(src)]) {
            var index = 0;
            var strRanges = {index: 1, ranges: ranges};

            while (matcher.find(index)) {
                index = matcher.end();

                if (!inDocRange(matcher.start(2), strRanges)) {
                    continue;
                }

                var group = [matcher.toMatchResult()];
                var indent = matcher.group(1);

                while (true) {
                    matcher.region(index, len(src));

                    if (matcher.lookingAt()) {
                        if (
                            inDocRange(matcher.start(2), strRanges) &&
                            len(indent) == len(matcher.group(1))
                        ) {
                            group.append(matcher.toMatchResult());
                            index = matcher.end();
                            continue;
                        }
                    }

                    if (arrayLen(group) > 1) {
                        replacements.append(parseDocParamGroup(group), true);
                    }
                    break;
                }
            }
        }

        replacements.sort(function(a, b) {
            if (a.start > b.start) return 1;
            if (a.start < b.start) return -1;
            return 0;
        });

        for (var replacement in replacements.reverse()) {
            src = src.substring(0, replacement.start) & replacement.line & src.substring(replacement.end);
        }

        return src;
    }

    private function parseAssignmentGroup(group) {
        var longestKey = getLongestAssignmentKey(group);
        var output = [];
        for (var match in group) {
            var key = match.group(2);
            key &= repeatString(' ', longestKey.longest - key.len());

            var value = longestKey.space & match.group(3).ltrim();
            output.append({start: match.start(2), end: match.end(3), line: key & value});
        }
        return output;
    }

    private function getLongestAssignmentKey(group) {
        var r = {longest: 0, space: ' '};
        for (var m in group) {
            r.longest = max(r.longest, m.end(2) - m.start(2));
            if (!m.group(3).startswith(' ')) {
                r.space = '';
            }
        }
        return r;
    }

    private function parseAttributes(match) {
        var src = match.group(2);
        var aMatcher = attributePattern.matcher(src);
        var index = 0;
        var result = {names: '', offset: match.start(2), attrs: []};

        while (aMatcher.find(index)) {
            index = aMatcher.end();
            result.names = result.names.listAppend(aMatcher.group(1));
            result.attrs.append(aMatcher.toMatchResult());
        }
        return result;
    }

    private function parseAttributeGroup(group) {
        var output = [];
        var longestValues = getLongestValues(group);
        for (var r in group) {
            for (var i = 1; i < r.attrs.len(); i++) {
                var padded = r.attrs[i].group();
                padded &= repeatString(' ', longestValues[i] - padded.len());
                output.append({start: r.attrs[i].start() + r.offset, end: r.attrs[i].end() + r.offset, line: padded});
            }
        }
        return output;
    }

    private function getLongestValues(group) {
        var longestValues = [];
        for (var i = 1; i < group[1].attrs.len(); i++) {
            var longest = 0;
            for (var r in group) {
                longest = max(longest, r.attrs[i].end() - r.attrs[i].start());
            }
            longestValues.append(longest);
        }
        return longestValues;
    }

    private function parseDocParamGroup(group) {
        var longestName = getLongestDocParamName(group);
        var output = [];
        for (var match in group) {
            var line = match.group(2);
            line &= repeatString(' ', longestName - line.len());
            line &= ' ' & match.group(3).ltrim();
            output.append({start: match.start(2), end: match.end(3), line: line.trim()});
        }
        return output;
    }

    private function getLongestDocParamName(group) {
        var longest = 0;
        for (var m in group) {
            longest = max(longest, m.end(2) - m.start(2));
        }
        return longest;
    }

    private function inStringRange(idx, strRanges) {
        while (
            strRanges.ranges.len() >= strRanges.index &&
            strRanges.ranges[strRanges.index].end - 1 < idx // end is first index after the range
        ) {
            strRanges.index++;
        }
        return (
            strRanges.ranges.len() >= strRanges.index &&
            strRanges.ranges[strRanges.index].start <= idx
        );
    }

    private function inDocRange(idx, strRanges) {
        while (
            strRanges.ranges.len() >= strRanges.index &&
            (
                strRanges.ranges[strRanges.index].end - 1 < idx ||
                strRanges.ranges[strRanges.index].name != 'doc_comment'
            )
        ) {
            strRanges.index++;
        }
        return (
            strRanges.ranges.len() >= strRanges.index &&
            strRanges.ranges[strRanges.index].start <= idx &&
            strRanges.ranges[strRanges.index].name == 'doc_comment'
        );
    }

}
