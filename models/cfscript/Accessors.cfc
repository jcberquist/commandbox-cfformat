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
        var counts = accessors.reduce((c, a, i) => {
            if (a.tokens.len() > 1) c.methods++;
            if (
                a.startComments.len() ||
                (a.endComment.len() && i < accessors.len())
            ) {
                c.comments++;
            }
            return c;
        }, {methods: 0, comments: 0});

        if (
            counts.comments == 0 &&
            (
                accessors.len() == 1 ||
                counts.methods < settings['method_call.chain.multiline']
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
            }

            if (counts.methods == 1 || !formatted.find(chr(10))) {
                if (accessors.last().endComment.len()) {
                    // we have an ending comment
                    formatted &= ' ' & accessor.endComment;
                    formatted &= settings.lf & cfformat.indentTo(indent, settings);
                }
                return formatted;
            }
        }

        // print on newlines
        var formatted = '';
        var firstMethodSeen = false;
        var lineComment = false;

        for (var accessor in accessors) {
            var isMethod = accessor.tokens.len() == 2;

            if (
                accessor.startComments.len() ||
                firstMethodSeen ||
                lineComment ||
                (
                    isMethod &&
                    columnOffset > ((indent + 1) * settings.indent_size)
                )
            ) {
                formatted &= settings.lf & cfformat.indentTo(indent + 1, settings);
            }

            firstMethodSeen = firstMethodSeen || isMethod;
            lineComment = false;

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
                formatted &= ' ' & accessor.endComment;
                lineComment = true;
            }
        }

        if (lineComment) {
            formatted &= settings.lf & cfformat.indentTo(indent, settings);
        }

        return formatted;
    }

    function collectAccessors(cftokens, settings, accessors = []) {
        var accessor = {startComments: [], tokens: [], endComment: ''};

        // are there comments
        while (
            cfformat.cfscript.comments.peekLineComment(cftokens, true) ||
            cftokens.peekElement('doc-comment') ||
            cftokens.peekElement('block-comment')
        ) {
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

        // is there an end comment
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
