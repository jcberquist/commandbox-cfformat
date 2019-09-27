component accessors="true" {

    variables.assignmentRegex = [
        '^([ \t,]*)', // leading indentation
        '(', // three possibilities
        '(?:var\s*)?[A-Za-z0-9$."'']+(?:\[[^\]]+\])*', // variable assignment
        '|',
        '(?i:param\s+)?[A-Za-z0-9$.]+(?:\s+[A-Za-z0-9$.]+)?', // params
        '|',
        '(?i:required\s+)?[A-Za-z0-9$.]+(?:\s+[A-Za-z0-9$.]+)?', // function parameters
        ')',
        '(\s*[:=][^\r\n]*)\r?\n'
    ];
    variables.commentRegex = '^[ \t]*//[^\r\n]*\r?\n';
    variables.propertiesRegex = [
        '^([ \t,]*)', // leading indentation
        '(?i:property)', // tag name
        '\s+',
        '((?:\s*',
        '[A-Za-z0-9$.]+', // attribute name
        '(?:',
        '\s*=\s*',
        '(?i:"[^"]*"|''[^'']*''|[A-Za-z0-9$.]+)', // attribute value
        ')?', // attribute value is optional
        ')*)',
        ';?\r?\n'
    ];
    variables.attributeRegex = [
        '([A-Za-z0-9$.]+)', // attribute name
        '(?:',
        '\s*=\s*',
        '(?:"[^"]*"|''[^'']*''|[A-Za-z0-9$.]+)', // attribute value
        ')?' // attribute value is optional
    ];

    function init() {
        var patternClass = createObject('java', 'java.util.regex.Pattern');
        variables.assignmentPattern = patternClass.compile(assignmentRegex.toList(''), 8);
        variables.commentPattern = patternClass.compile(commentRegex, 8);
        variables.propertiesPattern = patternClass.compile(propertiesRegex.toList(''), 8);
        variables.paramsPattern = patternClass.compile(propertiesRegex.toList('').replace('property', 'param'), 8);
        variables.attributePattern = patternClass.compile(attributeRegex.toList(''), 8);
        return this;
    }

    string function alignAssignments(required string src) {
        var aMatcher = assignmentPattern.matcher(src);
        var cMatcher = commentPattern.matcher(src);
        var index = 0;
        var replacements = [];

        while (aMatcher.find(index)) {
            index = aMatcher.end();
            var group = [aMatcher.toMatchResult()];
            var indent = aMatcher.group(1);

            while (true) {
                aMatcher.region(index, len(src));
                if (aMatcher.lookingAt()) {
                    if (len(indent) == len(aMatcher.group(1))) {
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
        var replacements = [];

        while (aMatcher.find(index)) {
            index = aMatcher.end();
            var group = [parseAttributes(aMatcher)];
            var indent = aMatcher.group(1);

            while (true) {
                aMatcher.region(index, len(src));
                if (aMatcher.lookingAt()) {
                    var parsed = parseAttributes(aMatcher);
                    if (
                        len(indent) == len(aMatcher.group(1)) &&
                        group.last().names == parsed.names
                    ) {
                        group.append(parsed);
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

    private function parseAssignmentGroup(group) {
        var longestKey = getLongestAssignmentKey(group);
        var output = [];
        for (var match in group) {
            var key = match.group(2);
            key &= repeatString(' ', longestKey - key.len());

            output.append({start: match.start(2), end: match.end(3), line: key & match.group(3)});
        }
        return output;
    }

    private function getLongestAssignmentKey(group) {
        var longestKey = 0;
        for (var m in group) {
            longestKey = max(longestKey, m.end(2) - m.start(2));
        }
        return longestKey;
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

}
