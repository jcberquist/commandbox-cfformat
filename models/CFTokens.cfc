component accessors=true {

    property tokens;
    property index;

    function init(array tokens) {
        variables.tokens = tokens;
        variables.index = 1;

        variables.nextTokenIndex = 0;
        variables.nextTextTokenIndex = 0;
        variables.nextCodeTokenIndex = 0;

        findNextTokens();

        return this;
    }

    function next(boolean whitespace = true, consumeNewline = false) {
        if (!arguments.whitespace) {
            consumeWhitespace(arguments.consumeNewline);
        }

        if (variables.index > tokens.len()) {
            return;
        }

        var token = tokens[variables.index];
        variables.index++;
        findNextTokens();
        return token;
    }

    function consumeWhitespace(consumeNewline = false) {
        variables.index = arguments.consumeNewline ? variables.nextTextTokenIndex : variables.nextTokenIndex;
        variables.nextTokenIndex = variables.index;
    }

    function peek(textOnly = false) {
        var i = arguments.textOnly ? variables.nextTextTokenIndex : variables.nextTokenIndex;
        if (i <= variables.tokens.len()) return variables.tokens[i];
    }

    boolean function nextIsElement() {
        if (variables.nextTokenIndex > variables.tokens.len()) {
            return false;
        }
        return isStruct(variables.tokens[nextTokenIndex]);
    }

    boolean function hasNext(boolean whitespace = true) {
        if (variables.index > tokens.len()) {
            return false;
        }
        return arguments.whitespace ? true : variables.nextTokenIndex;
    }

    boolean function peekText(text, textOnly = false) {
        var i = arguments.textOnly ? variables.nextTextTokenIndex : variables.nextTokenIndex;
        return i <= tokens.len() && isArray(tokens[i]) && tokens[i][1] == text;
    }

    boolean function peekScopes(scopes, textOnly = false) {
        var i = arguments.textOnly ? variables.nextTextTokenIndex : variables.nextTokenIndex;
        return (
            i <= variables.tokens.len() &&
            isArray(variables.tokens[i]) &&
            tokenMatches(variables.tokens[i], arguments.scopes)
        );
    }

    boolean function peekNewline(textOnly = false) {
        var i = arguments.textOnly ? variables.nextTextTokenIndex : variables.nextTokenIndex;
        return (
            i <= variables.tokens.len() &&
            isArray(variables.tokens[i]) &&
            variables.tokens[i][1].trim() == '' &&
            variables.tokens[i][1].endswith(chr(10)) &&
            (variables.tokens[i][2].len() == 0 || variables.tokens[i][2].last() != 'cfformat.ignore.cfml')
        );
    }

    boolean function peekBehindNewline() {
        var previousIndex = variables.index - 1;
        while (
            previousIndex > 0 &&
            isArray(variables.tokens[previousIndex]) &&
            !variables.tokens[previousIndex][1].endswith(chr(10)) &&
            variables.tokens[previousIndex][1].trim() == ''
        ) {
            previousIndex--;
        }
        return (
            previousIndex > 0 &&
            isArray(variables.tokens[previousIndex]) &&
            variables.tokens[previousIndex][1].endswith(chr(10)) &&
            (
                variables.tokens[previousIndex][2].len() == 0 ||
                variables.tokens[previousIndex][2].last() != 'cfformat.ignore.cfml'
            )
        );
    }

    boolean function peekScopeStartsWith(scopeString, textOnly = false) {
        var i = arguments.textOnly ? variables.nextTextTokenIndex : variables.nextTokenIndex;
        return (
            i <= variables.tokens.len() &&
            isArray(variables.tokens[i]) &&
            variables.tokens[i][2].last().startswith(arguments.scopeString)
        );
    }

    boolean function peekCodeScopeStartsWith(scopeString) {
        return (
            variables.nextCodeTokenIndex <= variables.tokens.len() &&
            isArray(variables.tokens[variables.nextCodeTokenIndex]) &&
            variables.tokens[variables.nextCodeTokenIndex][2].last().startswith(arguments.scopeString)
        );
    }

    boolean function peekElement(element) {
        var i = variables.nextTextTokenIndex;
        return (
            i <= variables.tokens.len() &&
            isStruct(variables.tokens[i]) &&
            variables.tokens[i].type == element
        );
    }

    boolean function tokenMatches(token, scopes) {
        var scopesLen = arguments.scopes.len();
        var tokenLen = arguments.token[2].len();

        if (scopesLen > tokenLen) return false;

        for (var i = 0; i < scopesLen; i++) {
            if (
                arguments.scopes[scopesLen - i] != '*' &&
                !arguments.token[2][tokenLen - i].startswith(arguments.scopes[scopesLen - i])
            ) {
                return false;
            }
        }
        return true;
    }

    function delimitedTokens(endScope, delimiterScope) {
        var startToken = next(false);
        var baseStack = startToken[2].slice(1, startToken[2].len() - 1);
        var delimiterStack = duplicate(baseStack).append(arguments.delimiterScope);
        var endStack = duplicate(baseStack).append(arguments.endScope);
        var cftokens = [];
        var tokens = [];

        while (hasNext()) {
            var token = next();

            if (tokenMatches(token, endStack)) {
                cftokens.append(new CFTokens(tokens));
                break;
            }
            if (tokenMatches(token, delimiterStack)) {
                cftokens.append(new CFTokens(tokens));
                tokens = [];
                continue;
            }
            tokens.append(token);
        }
        return cftokens;
    }

    function collectTo(scopes, elements) {
        if (!isArray(arguments.scopes)) arguments.scopes = [arguments.scopes];
        var tokens = [];
        while (hasNext()) {
            var terminate = false;
            if (nextIsElement()) {
                for (var element_type in arguments.elements) {
                    if (peekElement(element_type)) {
                        terminate = true;
                        break;
                    }
                }
                if (terminate) {
                    break;
                }
            } else {
                for (var scopeArray in arguments.scopes) {
                    if (tokenMatches(peek(), scopeArray)) {
                        terminate = true;
                        break;
                    }
                }
                if (terminate) {
                    break;
                }
            }
            tokens.append(next());
        }
        return new CFTokens(tokens);
    }

    function collectExpr() {
        var tokens = [];
        while (hasNext()) {
            if (peekNewline() || peekText(';')) {
                break;
            }
            tokens.append(next());
        }
        return new CFTokens(tokens);
    }

    private function findNextTokens() {
        variables.nextTokenIndex = 0;
        variables.nextTextTokenIndex = 0;
        variables.nextCodeTokenIndex = variables.index;

        while (
            variables.nextCodeTokenIndex <= variables.tokens.len() &&
            isArray(variables.tokens[variables.nextCodeTokenIndex]) &&
            variables.tokens[variables.nextCodeTokenIndex][1].trim() == ''
        ) {
            if (
                !variables.nextTokenIndex &&
                variables.tokens[variables.nextCodeTokenIndex][1].endswith(chr(10))
            ) {
                variables.nextTokenIndex = variables.nextCodeTokenIndex;
            }

            variables.nextCodeTokenIndex++;
        }

        variables.nextTextTokenIndex = variables.nextCodeTokenIndex;

        if (!variables.nextTokenIndex) {
            variables.nextTokenIndex = variables.nextTextTokenIndex;
        }

        while (variables.nextCodeTokenIndex <= variables.tokens.len()) {
            if (
                isArray(variables.tokens[variables.nextCodeTokenIndex]) &&
                variables.tokens[variables.nextCodeTokenIndex][1].trim() != '' &&
                !variables.tokens[variables.nextCodeTokenIndex][2].find('comment.line.double-slash.cfml')
            ) {
                break;
            }

            if (
                isStruct(variables.tokens[variables.nextCodeTokenIndex]) &&
                !['doc-comment', 'block-comment'].find(variables.tokens[variables.nextCodeTokenIndex].type)
            ) {
                break;
            }

            variables.nextCodeTokenIndex++;
        }
    }

}
