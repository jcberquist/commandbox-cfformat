component accessors="true" {

    variables.printers = [
        'CFTag',
        'CFTagBody',
        'TagComments',
        'TemplateExpression',
        'HTMLTag',
        'HTMLTagBody',
        'HTMLAttributes'
    ];

    function init(cfformat) {
        variables.cfformat = cfformat;
        variables.elementPrinters = {};
        variables.printerScopes = {};
        return this;
    }

    function construct() {
        for (var printer in printers) {
            this[printer] = new 'cftags.#printer#'(cfformat);
        }
        return this;
    }

    function registerElement(element_type, printer) {
        elementPrinters[element_type] = printer;
    }

    function register(scopes, printer) {
        for (var scope in scopes) {
            if (!printerScopes.keyExists(scope)) {
                printerScopes[scope] = [];
            }
            printerScopes[scope].append(printer);
        }
    }

    function print(
        cftokens,
        settings,
        indent = 0,
        columnOffset = indent * settings.indent_size,
        stopAt = [],
        context = 'base'
    ) {
        if (context == 'base') {
            return printCFTags(
                cftokens,
                settings,
                indent,
                columnOffset,
                stopAt
            );
        }
        if (context == 'sql') {
            return printSQL(
                cftokens,
                settings,
                indent,
                columnOffset,
                stopAt
            );
        }
        throw('Invalid context passed to tag printer.');
    }

    function printCFTags(
        cftokens,
        settings,
        indent = 0,
        columnOffset = indent * settings.indent_size,
        stopAt = []
    ) {
        var formattedText = '';

        if (stopAt.len() && !isArray(stopAt[1])) {
            stopAt = [stopAt];
        }

        while (
            cftokens.hasNext() &&
            (stopAt.len() == 0 || !stopAt.some((scopes) => cftokens.peekScopes(scopes)))
        ) {
            if (cftokens.nextIsElement()) {
                var element = cftokens.peek();

                var tagTxt = elementPrinters[element.type].print(
                    cftokens,
                    settings,
                    indent,
                    columnOffset
                );
                formattedText &= tagTxt;
            } else if (
                (cftokens.peekElement('cftag') || cftokens.peekElement('cftag-selfclosed'))
                && ['cfelse', 'cfelseif'].find(cftokens.peek(true).tagName)
            ) {
                // dedent by one to print cfelse and cfelseif
                cftokens.consumeWhitespace(true);
                formattedText &= settings.lf;
                formattedText &= cfformat.indentTo(indent - 1, settings);
            } else if (cftokens.peekNewline()) {
                // consume newline
                cftokens.next(false);
                formattedText &= settings.lf;
                cftokens.consumeWhitespace();
                if (cftokens.peekNewline()) {
                    // only allow two consecutive newlines
                    formattedText &= settings.lf;
                    cftokens.consumeWhitespace(true);
                }
                formattedText &= cfformat.indentTo(indent, settings);
            } else {
                // next token is not a newline so just add it
                var txt = cftokens.next()[1];
                if (txt.endswith(chr(10))) {
                    txt = txt.reReplace('\r?\n$', settings.lf);
                }
                if (!formattedText.endsWith(chr(10)) && reFind('\n\s+$', formattedText)) {
                    txt = txt.ltrim();
                }
                formattedText &= txt;
            }

            if (formattedText.endswith(chr(10))) {
                formattedText &= cfformat.indentTo(indent, settings);
            }
            columnOffset = cfformat.nextOffset(columnOffset, formattedText, settings);
        }

        return formattedText;
    }

    function printSQL(
        cftokens,
        settings,
        indent,
        columnOffset = indent * settings.indent_size,
        stopAt = []
    ) {
        var formattedText = '';

        if (stopAt.len() && !isArray(stopAt[1])) {
            stopAt = [stopAt];
        }

        while (
            cftokens.hasNext() &&
            (stopAt.len() == 0 || !stopAt.some((scopes) => cftokens.peekScopes(scopes)))
        ) {
            var token = cftokens.next();

            if (isStruct(token)) {
                var txt = elementPrinters[token.type].print(
                    cfformat.cftokens([token]),
                    settings,
                    indent,
                    columnOffset,
                    'sql'
                );
            } else {
                var txt = token[1];
                if (txt.endswith(chr(10))) {
                    txt = txt.rtrim() & settings.lf;
                }
            }

            if (
                formattedText.endswith(chr(10)) &&
                (txt.trim().len() || !txt.endswith(chr(10)))
            ) {
                var wsIndent = cfformat.calculateIndentSize(txt, settings);
                if (wsIndent > indent * settings.indent_size) {
                    txt = cfformat.indentToColumn(wsIndent, settings) & txt.ltrim();
                } else {
                    txt = cfformat.indentTo(indent, settings) & txt.ltrim();
                }
            }

            formattedText &= txt;
        }

        return formattedText;
    }

}
