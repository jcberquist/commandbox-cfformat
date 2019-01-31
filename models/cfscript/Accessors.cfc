component {

    property cfformat;

    function init(cfformat) {
        variables.cfformat = cfformat;
        cfformat.cfscript.register('punctuation.accessor.', this, true);
        return this;
    }

    function print(
        cftokens,
        settings,
        indent,
        columnOffset
    ) {
        var accessors = collectAccessors(cftokens);
        var methodCallCount = accessors.reduce((c, a) => {
            if (a.len() == 2) c++;
            return c;
        }, 0);

        if (methodCallCount < 3) {
            // print inline
            var formatted = '';
            for (var accessor in accessors) {
                formatted &= '.' & accessor[1][1];
                columnOffset = cfformat.nextOffset(columnOffset, formatted, settings);
                if (accessor.len() == 2) {
                    formatted &= cfformat.cfscript.FunctionCalls.print(
                        cfformat.cftokens([accessor[2]]),
                        settings,
                        indent,
                        columnOffset
                    )
                }
            }

            if (methodCallCount == 1 || !formatted.find(chr(10))) {
                return formatted.rtrim();
            }
        }

        // print on newlines
        var formatted = '';
        var firstMethodSeen = false;
        for (var accessor in accessors) {
            if (!firstMethodSeen && accessor.len() == 2) {
                if (columnOffset > (indent + 1) * settings.indent_size) {
                    formatted &= settings.lf & cfformat.indentTo(indent + 1, settings);
                }
                firstMethodSeen = true;
            }

            formatted &= '.' & accessor[1][1];
            columnOffset = cfformat.nextOffset(columnOffset, formatted, settings);
            if (accessor.len() == 2) {
                formatted &= cfformat.cfscript.FunctionCalls.print(
                    cfformat.cftokens([accessor[2]]),
                    settings,
                    indent + 1,
                    columnOffset
                )
                formatted &= settings.lf & cfformat.indentTo(indent + 1, settings);
            }
        }

        return formatted.rtrim();
    }

    function collectAccessors(cftokens, accessors = []) {
        // collect the period
        cftokens.next(false, true);
        var tokens = [cftokens.next(false)];
        if (['variable.function.cfml', 'support.function.member.cfml'].find(tokens[1][2].last())) {
            // this is a method call, collect arguments
            tokens.append(cftokens.next(false));
        }

        accessors.append(tokens);

        if (cftokens.peekScopeStartsWith('punctuation.accessor', true)) {
            return collectAccessors(cftokens, accessors);
        }
        return accessors;
    }

}
