component accessors="true" {

    variables.printers = [
        'Keywords',
        'Operators',
        'Structs',
        'Arrays',
        'Strings',
        'Blocks',
        'Brackets',
        'Comments',
        'Accessors',
        'FunctionCalls',
        'Groups',
        'ScriptTags',
        'Functions',
        'CFComponent',
        'Attributes'
    ];

    function init(cfformat) {
        variables.cfformat = cfformat;
        variables.elementPrinters = {};
        variables.scopePrinters = [];
        return this;
    }

    function construct() {
        for (var printer in printers) {
            this[printer] = new 'cfscript.#printer#'(cfformat, this);
        }
        return this;
    }

    function registerElement(element_type, printer) {
        elementPrinters[element_type] = printer;
    }

    function register(scope, printer, lookPastNewline = false) {
        scopePrinters.append({scope: scope, printer: printer, textOnly: lookPastNewline});
    }

    function print(
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
                var printerTxt = elementPrinters[cftokens.peek().type].print(
                    cftokens,
                    settings,
                    indent,
                    columnOffset
                );
                columnOffset = cfformat.nextOffset(columnOffset, printerTxt, settings);
                formattedText &= printerTxt;
                continue;
            }

            var handledByPrinter = false;
            for (var sp in scopePrinters) {
                if (cftokens.peekScopeStartsWith(sp.scope, sp.textOnly)) {
                    var printerTxt = sp.printer.print(
                        cftokens,
                        settings,
                        indent,
                        columnOffset
                    );
                    if (!isNull(printerTxt)) {
                        columnOffset = cfformat.nextOffset(columnOffset, printerTxt, settings);
                        formattedText &= printerTxt;
                        handledByPrinter = true;
                        break;
                    }
                }
            }
            if (handledByPrinter) continue;

            // check for newline
            if (cftokens.peekNewline()) {
                // consume newline and following whitespace
                cftokens.next(false);
                cftokens.consumeWhitespace();
                formattedText &= settings.lf;
                if (!cftokens.peekNewline()) {
                    formattedText &= cfformat.indentTo(indent, settings);
                }
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

}
