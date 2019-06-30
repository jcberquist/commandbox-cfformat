component accessors="true" {

    property defaultSettings;

    function init(cfformat) {
        variables.cfformat = cfformat;
        cfformat.cftags.registerElement('block-comment', this);
        return this;
    }

    function print(
        cftokens,
        settings,
        indent,
        columnOffset
    ) {
        var element = cftokens.next(false);

        var lines = element.elements
            .map((t) => {
                if (isArray(t)) return t[1];
                return print(
                    cfformat.cftokens([t]),
                    settings,
                    indent,
                    columnOffset
                );
            })
            .toList('')
            .trim()
            .listToArray(chr(10));

        if (
            lines.len() == 1 &&
            lines[1].trim().len() + columnOffset + 11 <= settings.max_columns // count <!--- and --->
        ) {
            var txt = lines[1].trim();
            var spacer = txt.startswith('-') ? '' : ' ';
            return '<!---' & spacer & txt & spacer & '--->';
        }

        lines = lines.map((line) => line.trim());

        var formatted = '<!---';

        if (lines[1].startswith('-')) {
            formatted &= lines.toList(cfformat.indentTo(indent, settings) & settings.lf);
            formatted &= '--->';
        } else {
            var indentString = cfformat.indentTo(indent + 1, settings);
            formatted &= settings.lf & indentString;
            formatted &= lines.toList(settings.lf & indentString);
            formatted &= settings.lf & cfformat.indentTo(indent, settings) & '--->';
        }

        return formatted;
    }

}
