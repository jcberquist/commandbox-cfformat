component {

    property tokens;
    property index;
    property previousIndex;
    property peekIndex;

    function init(array tokens) {
        variables.tokens = tokens;
        variables.index = 1;

        variables.previousTokenIndex = 0;
        variables.previousTextTokenIndex = 0;
        variables.nextTokenIndex = 0;
        variables.nextTextTokenIndex = 0;

        findNextTokens();

        return this;
    }

    function getTokens() {
        return variables.tokens;
    }

    function next(boolean whitespace = true, consumeNewline = false) {
        if (!whitespace) {
            consumeWhitespace(consumeNewline);
        }

        if (index > tokens.len()) {
            return;
        }

        var token = tokens[index];

        if (!isArray(token) || token[1].trim() != '') {
            previousTokenIndex = index;
            previousTextTokenIndex = index;
        } else if (token[1].trim() == '' && token[1].endswith(chr(10))) {
            previousTokenIndex = index;
        }

        index++;
        findNextTokens();
        return token;
    }

    function consumeWhitespace(consumeNewline = false) {
        index = consumeNewline ? nextTextTokenIndex : nextTokenIndex;
        nextTokenIndex = index;
    }

    function peek(textOnly = false) {
        var i = textOnly ? nextTextTokenIndex : nextTokenIndex;
        if (i <= tokens.len()) return tokens[i];
    }

    function peekBehind(textOnly = false) {
        var i = textOnly ? previousTextTokenIndex : previousTokenIndex;
        if (i) return tokens[i];
    }

    boolean function nextIsElement() {
        if (nextTokenIndex > tokens.len()) {
            return false;
        }
        return isStruct(tokens[nextTokenIndex]);
    }

    boolean function hasNext(boolean whitespace = true) {
        if (index > tokens.len()) {
            return false;
        }
        return whitespace ? true : nextTokenIndex;
    }

    boolean function peekText(text, textOnly = false) {
        var i = textOnly ? nextTextTokenIndex : nextTokenIndex;
        return i <= tokens.len() && isArray(tokens[i]) && tokens[i][1] == text;
    }

    boolean function peekScopes(scopes, textOnly = false) {
        var i = textOnly ? nextTextTokenIndex : nextTokenIndex;
        return i <= tokens.len() && isArray(tokens[i]) && tokenMatches(tokens[i], scopes);
    }

    boolean function peekNewline(textOnly = false) {
        var i = textOnly ? nextTextTokenIndex : nextTokenIndex;
        return (
            i <= tokens.len() &&
            isArray(tokens[i]) &&
            tokens[i][1].trim() == '' &&
            tokens[i][1].endswith(chr(10))
        );
    }

    boolean function peekScopeStartsWith(scopeString, textOnly = false) {
        var i = textOnly ? nextTextTokenIndex : nextTokenIndex;
        return i <= tokens.len() && isArray(tokens[i]) && tokens[i][2].last().startswith(scopeString);
    }

    boolean function peekElement(element) {
        var i = nextTextTokenIndex;
        return i <= tokens.len() && isStruct(tokens[i]) && tokens[i].type == element;
    }

    boolean function tokenMatches(token, scopes) {
        var scopesLen = scopes.len();
        var tokenLen = token[2].len();

        if (scopesLen > tokenLen) return false;

        for (var i = 0; i < scopesLen; i++) {
            if (scopes[scopesLen - i] != '*' && !token[2][tokenLen - i].startswith(scopes[scopesLen - i])) {
                return false;
            }
        }
        return true;
    }

    function delimitedTokens(endScope, delimiterScope) {
        var startToken = next(false);
        var baseStack = startToken[2].slice(1, startToken[2].len() - 1);
        var delimiterStack = duplicate(baseStack).append(delimiterScope);
        var endStack = duplicate(baseStack).append(endScope);
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
        if (!isArray(scopes)) scopes = [scopes];
        var tokens = [];
        while (hasNext()) {
            var terminate = false;
            if (nextIsElement()) {
                for (var element_type in elements) {
                    if (peekElement(element_type)) {
                        terminate = true;
                        break;
                    }
                }
                if (terminate) {
                    break;
                }
            } else {
                for (var scopeArray in scopes) {
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
        nextTokenIndex = 0;
        nextTextTokenIndex = index;
        while (
            nextTextTokenIndex <= tokens.len() &&
            isArray(tokens[nextTextTokenIndex]) &&
            tokens[nextTextTokenIndex][1].trim() == ''
        ) {
            if (
                tokens[nextTextTokenIndex][1].trim() == '' &&
                tokens[nextTextTokenIndex][1].endswith(chr(10)) &&
                !nextTokenIndex
            ) {
                nextTokenIndex = nextTextTokenIndex;
            }
            nextTextTokenIndex++;
        }
        if (!nextTokenIndex) {
            nextTokenIndex = nextTextTokenIndex;
        }
    }

}
