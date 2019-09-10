component accessors="true" {

    variables.assignmentRegex = [
        '^([ \t]*)', // leading indentation
        '(', // two possibilities
        '(?:var\s*)?[A-Za-z0-9$.]+(?:\[[^\]]+\])*', // variable assignment
        '|',
        '(?i:required\s+)?[A-Za-z0-9$.]+(?:\s+[A-Za-z0-9$.]+)?', // function parameters
        ')',
        '(\s*[:=][^\r\n]*)\r?\n'
    ];
    variables.commentRegex = '^[ \t]*//[^\r\n]*\r?\n';


    function init() {
        var patternClass = createObject('java', 'java.util.regex.Pattern');
        variables.assignmentPattern = patternClass.compile(assignmentRegex.toList(''), 8);
        variables.commentPattern = patternClass.compile(commentRegex, 8);
        return this;
    }

    string function align(required string src) {
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
                if (aMatcher.lookingAt() && indent == aMatcher.group(1)) {
                    group.append(aMatcher.toMatchResult());
                    index = aMatcher.end();
                    continue;
                } else {
                    cMatcher.region(index, len(src));
                    if (cMatcher.lookingAt()) {
                        index = cMatcher.end();
                        continue;
                    }
                }

                if (arrayLen(group) > 1) {
                    replacements.append(parseGroup(group), true);
                }
                break;
            }
        }

        for (var replacement in replacements.reverse()) {
            src = src.substring(0, replacement.start) & replacement.line & src.substring(replacement.end);
        }

        return src;
    }

    private function parseGroup(group) {
        var longestKey = getLongestKey(group);
        var output = [];
        for (var match in group) {
            var key = match.group(2);
            key &= repeatString(' ', longestKey - key.len());

            output.append({start: match.start(2), end: match.end(3), line: key & match.group(3)});
        }
        return output;
    }

    private function getLongestKey(group) {
        var longestKey = 0;
        for (var m in group) {
            longestKey = max(longestKey, m.end(2) - m.start(2));
        }
        return longestKey;
    }

}
