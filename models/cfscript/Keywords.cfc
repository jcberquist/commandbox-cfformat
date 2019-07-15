component {

    property cfformat;

    variables.forSemicolon = ['meta.for.cfml', 'meta.group.cfml', 'punctuation.terminator.statement.cfml'];
    variables.keywordScopes = [
        'keyword.control.loop.cfml',
        'keyword.control.conditional.cfml',
        'keyword.control.trycatch.cfml',
        'keyword.control.switch.cfml'
    ];

    function init(cfformat) {
        variables.cfformat = cfformat;
        cfformat.cfscript.register('keyword.control.', this);
        cfformat.cfscript.register('punctuation.terminator.', this);
        return this;
    }

    function print(
        cftokens,
        settings,
        indent,
        columnOffset
    ) {
        if (cftokens.peekScopes(forSemicolon)) {
            cftokens.next(whitespace = false);
            cftokens.consumeWhitespace(true);
            var spacer = settings['for_loop_semicolons.padding'] ? ' ' : '';
            return ';' & spacer;
        }

        if (!cftokens.peekScopeStartsWith('keyword.control.')) return;

        // check for switch
        if (
            cftokens.peekScopeStartsWith('keyword.control.switch.') &&
            !cftokens.peekText('switch')
        ) {
            return printSwitchCase(
                cftokens,
                settings,
                indent,
                columnOffset
            );
        }

        for (var scope in keywordScopes) {
            if (cftokens.peekScopes([scope])) {
                return printKeyword(
                    cftokens,
                    settings,
                    indent,
                    columnOffset
                );
            }
        }

        // if we get here, we are dealing with a keyword such as `return`
        // print it with a following whitespace unless
        // next token after it is a semicolon
        var keyword = cftokens.next(whitespace = false);
        cftokens.consumeWhitespace(true);
        if (!cftokens.peekText(';', true)) {
            return keyword[1] & ' ';
        }
        return keyword[1];
    }

    function printKeyword(
        cftokens,
        settings,
        indent,
        columnOffset
    ) {
        var formatted = '';

        // handle the keyword itself
        var keywordToken = cftokens.next(whitespace = false);
        var keyword = keywordToken[1];
        formatted &= keyword;

        // special case for a `throw`:
        if (keyword == 'throw') {
            cftokens.consumeWhitespace(true);
            if (!cftokens.peekText(';', true)) {
                formatted &= ' ';
            }
            return formatted;
        }

        // check for a group
        var renderedGroup = false;
        if (
            [
                'if',
                'else if',
                'while',
                'for',
                'catch',
                'switch'
            ].find(keyword)
        ) {
            formatted &= settings['keywords.spacing_to_group'] ? ' ' : '';
            cftokens.consumeWhitespace(true);
            var groupFormatted = cfformat.cfscript.groups.print(
                cftokens,
                settings,
                indent,
                columnOffset + formatted.len(),
                formatted.right(1),
                settings['keywords.padding_inside_group'],
                settings['keywords.empty_group_spacing']
            );
            if (!isNull(groupFormatted)) {
                formatted &= groupFormatted;
                renderedGroup = true;
            } else {
                // if we didn't find expected group, for now just return out
                return formatted;
            }
        }

        // check for a block or statement
        if (
            [
                'if',
                'while',
                'for',
                'else',
                'else if',
                'do',
                'try',
                'catch',
                'finally',
                'switch'
            ].find(keyword)
        ) {
            if (cftokens.peekElement('block')) {
                var blockFormatted = cfformat.cfscript.blocks.print(
                    cftokens,
                    settings,
                    indent,
                    columnOffset + formatted.len()
                );
                var setting = renderedGroup ? settings['keywords.group_to_block_spacing'] : settings[
                    'keywords.spacing_to_block'
                ];
                if (setting == 'spaced') {
                    formatted &= ' ';
                } else if (setting == 'newline') {
                    formatted &= settings.lf & cfformat.indentTo(indent, settings);
                }
                formatted &= blockFormatted;
            } else if (!cftokens.tokenMatches(keywordToken, ['meta.do-while.cfml', 'keyword.control.loop.cfml'])) {
                cftokens.consumeWhitespace(true);
                var tokens = cftokens.collectExpr();
                var statement = cfformat.cfscript.print(tokens, settings, indent + 1);
                if (columnOffset + formatted.len() + statement.len() > settings.max_columns) {
                    formatted &= settings.lf & cfformat.indentTo(indent + 1, settings);
                } else {
                    formatted &= ' ';
                }
                formatted &= statement.trim();
            }
        }

        // if we started with `if` or `else if` check for following `else`, `else if`
        // else if we started with `do`, check for `while`
        if (['if', 'else if'].find(keyword)) {
            var nextToken = cftokens.peek(true);
            if (!isNull(nextToken) && isArray(nextToken) && ['else if', 'else'].find(nextToken[1])) {
                formatted = formatted.rtrim();
                if (settings['keywords.block_to_keyword_spacing'] == 'spaced') {
                    formatted &= ' ';
                } else if (settings['keywords.block_to_keyword_spacing'] == 'newline') {
                    formatted &= settings.lf & cfformat.indentTo(indent, settings);
                }
                formatted &= printKeyword(
                    cftokens,
                    settings,
                    indent,
                    columnOffset
                );
            }
        } else if (['do', 'try', 'catch'].find(keyword)) {
            var nextToken = cftokens.peek(true);
            if (!isNull(nextToken) && ['while', 'catch', 'finally'].find(nextToken[1])) {
                formatted = formatted.rtrim();
                if (settings['keywords.block_to_keyword_spacing'] == 'spaced') {
                    formatted &= ' ';
                } else if (settings['keywords.block_to_keyword_spacing'] == 'newline') {
                    formatted &= settings.lf & cfformat.indentTo(indent, settings);
                }
                formatted &= printKeyword(
                    cftokens,
                    settings,
                    indent,
                    columnOffset
                );
            }
        }

        return formatted;
    }

    function printSwitchCase(
        cftokens,
        settings,
        indent,
        columnOffset
    ) {
        var formatted = '';

        // handle the keyword itself (case, default)
        var keywordToken = cftokens.next(whitespace = false);
        var keyword = keywordToken[1];
        formatted &= keyword;

        // print to the colon:
        var caseText = cfformat.cfscript
            .print(
                cftokens,
                settings,
                indent,
                columnOffset,
                ['meta.switch.cfml', 'meta.block.cfml', 'punctuation.separator.cfml']
            )
            .trim();

        if (caseText.len()) {
            formatted &= ' ' & caseText;
        }

        // consume colon
        formatted &= ':';
        cftokens.next(false);

        // check for a case block
        if (cftokens.peekElement('block')) {
            cftokens.consumeWhitespace(true);
            var caseBody = cfformat.cfscript.blocks.print(
                cftokens,
                settings,
                indent,
                (indent) * settings.indent_size
            );
            formatted &= ' ' & caseBody;
        } else {
            // print to next case statement
            var caseBody = cfformat.cfscript
                .print(
                    cftokens,
                    settings,
                    indent + 1,
                    (indent + 1) * settings.indent_size,
                    ['meta.switch.cfml', 'meta.block.cfml', 'keyword.control.switch']
                )
                .trim();

            if (caseBody.len()) {
                formatted &= settings.lf & cfformat.indentTo(indent + 1, settings) & caseBody.trim();
            }

            formatted &= settings.lf & cfformat.indentTo(indent, settings);
        }

        return formatted;
    }

}
