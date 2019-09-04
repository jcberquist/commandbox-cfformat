component accessors="true" {

    variables.assignmentRegex = '^(?:[ \t]*)((?:var\s*)?[A-Za-z0-9$.]+)(\s*[:=]\s*[^\{\[\s][^\r\n]*)\r?\n';
    variables.commentRegex = '^[ \t]*//[^\r\n]*\r?\n';


    function init() {
        var patternClass = createObject('java', 'java.util.regex.Pattern');
        variables.assignmentPattern = patternClass.compile(assignmentRegex, 8);
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

            while (true) {
                aMatcher.region(index, len(src));
                if (aMatcher.lookingAt()) {
                    group.append(aMatcher.toMatchResult());
                    index = aMatcher.end();
                    continue;
                }

                cMatcher.region(index, len(src));
                if (cMatcher.lookingAt()) {
                    index = cMatcher.end();
                    continue;
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
            var key = match.group(1);
            key &= repeatString(' ', longestKey - key.len());

            output.append({start: match.start(1), end: match.end(2), line: key & match.group(2)});
        }
        return output;
    }

    private function getLongestKey(group) {
        var longestKey = 0;
        for (var m in group) {
            longestKey = max(longestKey, m.end(1) - m.start(1));
        }
        return longestKey;
    }

}
