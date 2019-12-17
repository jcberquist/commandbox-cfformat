component accessors="true" {

    function init(cfformat) {
        variables.cfformat = cfformat;
        return this;
    }

    function printElements(scope, settings, indent) {
        var result = {printed: [], endingComments: {}, afterCommaComments: {}};

        for (var i = 1; i <= scope.delimited_elements.len(); i++) {
            var tokens = scope.delimited_elements[i];

            if (!tokens.len()) {
                result.printed.append('');
                continue;
            }

            var element_cftokens = cfformat.cftokens(tokens);

            if (i > 1 && cfformat.cfscript.comments.peekLineComment(element_cftokens)) {
                result.afterCommaComments[i - 1] = cfformat.cfscript.comments
                    .print(element_cftokens, settings, indent + 1)
                    .trim();
            }

            var endCommentIndex = endswithLineComments(element_cftokens);

            if (endCommentIndex) {
                var commentTokens = tokens.slice(endCommentIndex);
                element_cftokens.setTokens(endCommentIndex > 1 ? tokens.slice(1, endCommentIndex - 1) : []);
                result.endingComments[i] = cfformat.cfscript
                    .print(cfformat.cftokens(commentTokens), settings, indent + 1)
                    .rtrim();
            }

            var printedElement = cfformat.cfscript.print(element_cftokens, settings, indent + 1).trim();
            result.printed.append(printedElement);
        }

        return result;
    }

    function joinElements(
        type,
        printedElements,
        settings,
        indent
    ) {
        var elementNewLine = settings.lf & cfformat.indentTo(indent + 1, settings);
        var formattedText = elementNewLine;

        printedElements.printed.each((printed, i) => {
            if (settings['#type#.multiline.leading_comma']) {
                if (i == 1) {
                    formattedText &= settings['#type#.multiline.leading_comma.padding'] ? '  ' : ' ';
                } else {
                    formattedText &= settings['#type#.multiline.leading_comma.padding'] ? ', ' : ',';
                }
            }

            formattedText &= printed;

            if (!settings['#type#.multiline.leading_comma'] && i < printedElements.printed.len()) {
                formattedText &= ',';
            }

            if (printedElements.afterCommaComments.keyExists(i)) {
                formattedText &= ' ' & printedElements.afterCommaComments[i];
            }

            if (printedElements.endingComments.keyExists(i)) {
                var comment = printed.len() ? printedElements.endingComments[i] : printedElements.endingComments[i].ltrim();
                if (
                    formattedText.len() &&
                    !formattedText.endswith(' ') &&
                    !(comment.startswith(chr(13)) || comment.startswith(chr(10)))
                ) {
                    formattedText &= ' ';
                }
                formattedText &= comment;
            }

            if (i < printedElements.printed.len()) {
                formattedText &= elementNewLine;
            }
        });

        return formattedText;
    }

    function endswithLineComments(cftokens) {
        var tokens = cftokens.getTokens();
        var index = cftokens.getIndex();

        var commentsPresent = false;
        for (var i = tokens.len(); i >= index; i--) {
            var token = tokens[i];
            if (isArray(token) && token[2].find('comment.line.double-slash.cfml')) {
                commentsPresent = true;
                continue;
            }
            if (!isArray(token) || token[1].trim().len()) {
                return commentsPresent ? (i + 1) : 0;
            }
        }
        return commentsPresent ? index : 0;
    }

}
