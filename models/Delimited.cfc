component accessors="true" {

    function init(cfformat) {
        variables.cfformat = cfformat;
        return this;
    }

    function printElements(scope, settings, indent) {
        var result = {printed: [], endingComments: {}};

        for (var i = 1; i <= scope.delimited_elements.len(); i++) {
            var tokens = scope.delimited_elements[i];

            if (!tokens.len()) {
                result.printed.append('');
                continue;
            }

            var endCommentIndex = endswithLineComment(tokens);

            if (endCommentIndex) {
                var commentTokens = tokens.slice(endCommentIndex, tokens.len() - (endCommentIndex - 1));
                tokens = tokens.slice(1, endCommentIndex - 1);
                result.endingComments[i] = cfformat.cfscript.comments
                    .print(cfformat.cftokens(commentTokens), settings, indent + 1)
                    .trim();
            }

            var element_cftokens = cfformat.cftokens(tokens);

            if (i > 1 && cfformat.cfscript.comments.peekLineComment(element_cftokens)) {
                result.endingComments[i - 1] = cfformat.cfscript.comments
                    .print(element_cftokens, settings, indent + 1)
                    .trim();
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
        if (settings['#type#.multiline.leading_comma'] && settings['#type#.multiline.leading_comma.tab']) {
			var elementNewLine = settings.lf & cfformat.indentTo(indent, settings);
			var formattedText = elementNewLine;
            var delimiter = ',' & ( settings['tab_indent'] ? chr(9) : repeatString(' ', settings['indent_size']-1 ) );
            formattedText &= ( settings['tab_indent'] ? chr(9) : repeatString(' ', settings['indent_size'] ) );
            formattedText &= printedElements.printed.tolist(elementNewLine & delimiter);
		} else if (settings['#type#.multiline.leading_comma']) {
			var elementNewLine = settings.lf & cfformat.indentTo(indent + 1, settings);
			var formattedText = elementNewLine;
            var delimiter = settings['#type#.multiline.leading_comma.padding'] ? ', ' : ',';
            formattedText &= repeatString(' ', delimiter.len());
            formattedText &= printedElements.printed.tolist(elementNewLine & delimiter);
        } else {
			var elementNewLine = settings.lf & cfformat.indentTo(indent + 1, settings);
			var formattedText = elementNewLine;
            printedElements.printed.each((printed, i) => {
                formattedText &= printed;

                if (i < printedElements.printed.len()) {
                    formattedText &= ',';
                }

                if (printedElements.endingComments.keyExists(i)) {
                    formattedText &= (printed.len() ? ' ' : '') & printedElements.endingComments[i];
                }

                if (i < printedElements.printed.len()) {
                    formattedText &= elementNewLine;
                }
            });
        }

        return formattedText;
    }

    function endswithLineComment(tokens) {
        for (var i = tokens.len(); i > 0; i--) {
            var token = tokens[i];
            if (!isArray(token)) return 0;
            if (token[2].last() == 'comment.line.double-slash.cfml') return i - 1;
            if (token[1].trim().len()) return 0;
        }
        return 0;
    }

}
