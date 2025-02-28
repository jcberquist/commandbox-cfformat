component accessors="true" {

    variables.identifier = '[A-Za-z0-9$._]+';
    variables.docParam = '@[A-Za-z0-9$._:-]+';

    variables.assignmentRegex = [
        '^([ \t,]*)', // leading indentation
        '(', // three possibilities
        '(?:var\s*)?(?i:"[^"]*"|''[^'']*''|#identifier#)(?:\[[^\]]+\])*', // variable assignment
        '|',
        '(?i:param[ \t]+)?#identifier#(?:[ \t]+#identifier#)?', // params
        '|',
        '(?i:required[ \t]+)?#identifier#(?:[ \t]+#identifier#)?', // function parameters
        ')',
        '([ \t]*[:=](?![:=])[^\r\n]*)\r?\n'
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
    variables.docLineRegex = [
        '^([ \t]*\*)', // leading indentation and *
        '(?:[ \t]*',
        '(',
        '@throws #identifier#', // throws
        '|',
        docParam, // param or return
        '))?', // this is optional
        '([^\r\n]*\r?\n)' // rest of the line
    ];

    function init() {
        var patternClass = createObject('java', 'java.util.regex.Pattern');
        variables.stringRanges = new StringRanges();
        variables.assignmentPattern = patternClass.compile(assignmentRegex.toList(''), 8);
        variables.commentPattern = patternClass.compile(commentRegex, 8);
        variables.propertiesPattern = patternClass.compile(propertiesRegex.toList(''), 8);
        variables.paramsPattern = patternClass.compile(propertiesRegex.toList('').replace('property', 'param'), 8);
        variables.attributePattern = patternClass.compile(attributeRegex.toList(''), 8);
        variables.docLinePattern = patternClass.compile(docLineRegex.toList(''), 8);
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
        var ranges = stringRanges.walk(src);
        var replacements = [];

        for (var range in ranges) {
            if (range.name != 'doc_comment') {
                continue;
            }

            var docComment = src.substring(range.start, range.end);

            if (!docComment.find(chr(10))) {
                continue;
            }

            var lines = docComment.listToArray(chr(10));
            if (lines.len() < 3) {
                continue;
            }

            if (arrayFind(lines.slice(2, lines.len() - 1), (l) => !l.ltrim().startswith('*'))) {
                continue;
            }

            var lf = docComment.find(chr(13)) ? chr(13) & chr(10) : chr(10);
            var matcher = docLinePattern.matcher(docComment);
            var index = 0;
            var indent = '';
            var emptyLine = '';
            var restOfLine = '';

            var lines = {
                docs: [],
                params: [],
                return: [],
                throws: [],
                maxThrowLen: 0,
                maxParamLen: 0
            }

            while (matcher.find(index)) {
                index = matcher.end();
                indent = matcher.group(1);
                emptyLine = indent & lf;
                restOfLine = (matcher.group(3) ?: '');

                if (isNull(matcher.group(2))) {
                    // this is a regular line
                    if (
                        matcher.group(0) != emptyLine ||
                        !lines.docs.len() ||
                        lines.docs.last() != emptyLine
                    ) {
                        lines.docs.append(indent & restOfLine);
                    }
                } else {
                    var tag = matcher.group(2);

                    if (restOfLine.trim().len()) {
                        restOfLine = ' ' & restOfLine.ltrim();
                    }

                    if (tag == '@return' || tag == '@returns') {
                        lines.return.append(indent & ' @return' & restOfLine);
                    } else if (tag.startswith('@throws')) {
                        lines.maxThrowLen = max(lines.maxThrowLen, tag.len());
                        lines.throws.append([tag, restOfLine]);
                    } else {
                        lines.maxParamLen = max(lines.maxParamLen, tag.len());
                        lines.params.append([tag, restOfLine]);
                    }
                }
            }

            // build the comment
            var formattedLines = [];

            formattedLines.append(lines.docs, true);

            // params
            if (lines.params.len()) {
                if (formattedLines.len() && formattedLines.last() != emptyLine) {
                    formattedLines.append(emptyLine);
                }
                for (var line in lines.params) {
                    var formattedLine = indent & ' ' & line[1];
                    formattedLine &= repeatString(' ', lines.maxParamLen - line[1].len());
                    formattedLine &= line[2];
                    formattedLines.append(formattedLine)
                }
            }

            // return
            if (lines.return.len()) {
                if (formattedLines.len() && formattedLines.last() != emptyLine) {
                    formattedLines.append(emptyLine);
                }
                formattedLines.append(lines.return, true);
            }

            // throws
            if (lines.throws.len()) {
                if (formattedLines.len() && formattedLines.last() != emptyLine) {
                    formattedLines.append(emptyLine);
                }
                for (var line in lines.throws) {
                    var formattedLine = indent & ' ' & line[1];
                    formattedLine &= repeatString(' ', lines.maxThrowLen - line[1].len());
                    formattedLine &= line[2];
                    formattedLines.append(formattedLine)
                }
            }

            var formatted = docComment.listFirst(chr(10)) & chr(10);
            formatted &= formattedLines.toList('');
            formatted &= docComment.listLast(chr(10));
            replacements.append({start: range.start, end: range.end, docComment: formatted});
        }

        for (var replacement in replacements.reverse()) {
            src = src.substring(0, replacement.start) & replacement.docComment & src.substring(replacement.end);
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
