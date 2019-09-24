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

                continue;
            }

            // look for cfelse and cfelseif
            // dedent by one to print them
            if (
                (cftokens.peekElement('cftag') || cftokens.peekElement('cftag-selfclosed'))
                && ['cfelse', 'cfelseif'].find(cftokens.peek(true).tagName)
            ) {
                cftokens.consumeWhitespace(true);
                formattedText &= settings.lf;
                formattedText &= repeatString('    ', indent - 1);
                continue;
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
                columnOffset = indent * settings.indent_size;
            } else {
                // next token is not a newline so just add it
                var txt = cftokens.next()[1];
                formattedText &= txt;
                columnOffset += txt.len();
            }
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
        cftokens.consumeWhitespace(true);

        var formattedText = '';
        var afterNewline = false;

        if (stopAt.len() && !isArray(stopAt[1])) {
            stopAt = [stopAt];
        }

        while (
            cftokens.hasNext() &&
            (stopAt.len() == 0 || !stopAt.some((scopes) => cftokens.peekScopes(scopes)))
        ) {
            var token = cftokens.next();

            if (isStruct(token)) {
                // look for cfelse and cfelseif
                // dedent by one to print them
                if (
                    (token.type == 'cftag' || token.type == 'cftag-selfclosed')
                    && ['cfelse', 'cfelseif'].find(token.tagName)
                ) {
                    formattedText = formattedText.rtrim() & settings.lf;
                    formattedText &= repeatString('    ', indent - 1);
                }

                var tagTxt = elementPrinters[token.type].print(
                    cfformat.cftokens([token]),
                    settings,
                    indent,
                    columnOffset,
                    'sql'
                );
                formattedText &= tagTxt;
                afterNewline = false;
            } else {
                var txt = token[1];

                if (afterNewline) {
                    var wsIndent = cfformat.calculateIndentSize(token[1], settings);
                    if (wsIndent > indent * settings.indent_size) {
                        formattedText &= cfformat.indentToColumn(wsIndent, settings);
                        columnOffset = wsIndent;
                    } else {
                        formattedText &= cfformat.indentTo(indent, settings);
                        columnOffset = indent * settings.indent_size;
                    }
                    txt = txt.ltrim();
                    afterNewline = false;
                }

                formattedText &= txt;

                // does this token contain a new line?
                if (token[1].endswith(chr(10))) {
                    formattedText = formattedText.rtrim() & settings.lf;
                    columnOffset = indent * settings.indent_size;
                    afterNewline = true;
                } else {
                    columnOffset += txt.len();
                }
            }
        }

        return formattedText;
    }

}
