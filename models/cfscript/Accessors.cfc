component {

    property cfformat;

    function init(cfformat) {
        variables.cfformat = cfformat;
        cfformat.cfscript.register(
            'punctuation.accessor.',
            this,
            true,
            true
        );
        return this;
    }

    function print(
        cftokens,
        settings,
        indent,
        columnOffset
    ) {
        var accessors = collectAccessors(cftokens, settings);
        var counts = accessors.reduce((c, a) => {
            if (a.tokens.len() > 1) c.methods++;
            if (a.startComments.len() || a.endComment.len()) c.comments++;
            return c;
        }, {methods: 0, comments: 0});

        if (
            (accessors.len() == 1 && accessors[1].startComments.len() == 0) ||
            (
                counts.methods < settings['method_call.chain.multiline'] &&
                counts.comments == 0
            )
        ) {
            // print inline
            var formatted = '';
            for (var accessor in accessors) {
                formatted &= '.' & accessor.tokens[1][1];
                columnOffset = cfformat.nextOffset(columnOffset, formatted, settings);
                if (accessor.tokens.len() == 2) {
                    formatted &= cfformat.cfscript.FunctionCalls.print(
                        cfformat.cftokens([accessor.tokens[2]]),
                        settings,
                        indent,
                        columnOffset
                    )
                }
                if (accessor.endComment.len()) {
                    // we have an ending comment
                    formatted &= ' ' & accessor.endComment;
                }
            }

            if (counts.methods == 1 || !formatted.find(chr(10))) {
                return formatted.rtrim();
            }
        }

        // print on newlines
        var formatted = '';
        var firstMethodSeen = false;
        var lineBreak = false;

        for (var accessor in accessors) {
            if (accessor.startComments.len() && !lineBreak) {
                formatted &= settings.lf & cfformat.indentTo(indent + 1, settings);
            }

            if (!firstMethodSeen && accessor.tokens.len() == 2) {
                if (!accessor.startComments.len() && columnOffset > (indent + 1) * settings.indent_size && !lineBreak) {
                    formatted &= settings.lf & cfformat.indentTo(indent + 1, settings);
                }
                firstMethodSeen = true;
            }

            for (var startComment in accessor.startComments) {
                formatted &= startComment;
                formatted &= settings.lf & cfformat.indentTo(indent + 1, settings);
            }

            formatted &= '.' & accessor.tokens[1][1];
            columnOffset = cfformat.nextOffset(columnOffset, formatted, settings);
            if (accessor.tokens.len() > 1) {
                formatted &= cfformat.cfscript.FunctionCalls.print(
                    cfformat.cftokens([accessor.tokens[2]]),
                    settings,
                    indent + 1,
                    columnOffset
                )
            }
            if (accessor.endComment.len()) {
                // we have an ending comment
                formatted &= ' ' & accessor.endComment;
            }

            lineBreak = accessor.tokens.len() > 1 || accessor.endComment.len();
            if (lineBreak) {
                formatted &= settings.lf & cfformat.indentTo(indent + 1, settings);
            }
        }

        return formatted.rtrim();
    }

    function collectAccessors(cftokens, settings, accessors = []) {
        var accessor = {startComments: [], tokens: [], endComment: ''};

        // are there line comments
        while (cfformat.cfscript.comments.peekLineComment(cftokens, true)) {
            cftokens.consumeWhitespace(true);
            accessor.startComments.append(cfformat.cfscript.comments.print(cftokens, settings, 0).trim());
        }

        // collect the period
        cftokens.next(false, true);
        accessor.tokens.append(cftokens.next(false));
        if (['variable.function.cfml', 'support.function.member.cfml'].find(accessor.tokens[1][2].last())) {
            // this is a method call, collect arguments
            accessor.tokens.append(cftokens.next(false));
        }

        // is there a line comment
        if (cfformat.cfscript.comments.peekLineComment(cftokens)) {
            accessor.endComment = cfformat.cfscript.comments.print(cftokens, settings, 0).trim();
        }

        accessors.append(accessor);

        if (cftokens.peekCodeScopeStartsWith('punctuation.accessor')) {
            return collectAccessors(cftokens, settings, accessors);
        }
        return accessors;
    }

}
