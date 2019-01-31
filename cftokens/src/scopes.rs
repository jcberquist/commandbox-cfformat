pub struct DelimitedScope<'a> {
    pub name: &'a str,
    pub start: &'a str,
    pub delimiter: &'a str,
    pub end: &'a str
}

impl<'a> DelimitedScope<'a> {

    pub fn new(name: &'a str, start: &'a str, delimiter: &'a str, end: &'a str) -> DelimitedScope<'a> {
        DelimitedScope {
            name,
            start,
            delimiter,
            end
        }
    }
}

pub struct ContainerScope<'a> {
    pub name: &'a str,
    pub start: &'a str,
    pub end: &'a str
}

impl<'a> ContainerScope<'a> {

    pub fn new(name: &'a str, start: &'a str, end: &'a str) -> ContainerScope<'a> {
        ContainerScope {
            name,
            start,
            end
        }
    }
}

pub const DELIMITED_SCOPES: [(&str, &str, &str, &str); 7] = [
    (
        "struct",
        "meta.struct-literal.cfml punctuation.section.block.begin.cfml",
        "punctuation.separator.struct-literal.cfml",
        "punctuation.section.block.end.cfml"
    ),
    (
        "array",
        "meta.array-literal.cfml punctuation.section.brackets.begin.cfml",
        "punctuation.separator.array-literal.cfml",
        "punctuation.section.brackets.end.cfml"
    ),
    (
        "function-call",
        "meta.function-call.parameters.cfml punctuation.section.group.begin.cfml",
        "punctuation.separator.function-call.cfml",
        "punctuation.section.group.end.cfml"
    ),
    (
        "function-call",
        "meta.function-call.parameters.method.cfml punctuation.section.group.begin.cfml",
        "punctuation.separator.function-call.method.cfml",
        "punctuation.section.group.end.cfml"
    ),
    (
        "function-call",
        "meta.function-call.parameters.support.cfml punctuation.section.group.begin.cfml",
        "punctuation.separator.function-call.support.cfml",
        "punctuation.section.group.end.cfml"
    ),
    (
        "function-call",
        "meta.function-call.parameters.method.support.cfml punctuation.section.group.begin.cfml",
        "punctuation.separator.function-call.method.support.cfml",
        "punctuation.section.group.end.cfml"
    ),
    (
        "function-parameters",
        "meta.function.parameters.cfml punctuation.section.parameters.begin.cfml",
        "punctuation.separator.parameter.function.cfml",
        "punctuation.section.parameters.end.cfml"
    )
];

pub const CONTAINER_SCOPES: [(&str, &str, &str); 13] = [
    (
        "block",
        "meta.block.cfml punctuation.section.block.begin.cfml",
        "punctuation.section.block.end.cfml"
    ),
    (
        "block",
        "meta.function.body.cfml punctuation.section.block.begin.cfml",
        "punctuation.section.block.end.cfml"
    ),
    (
        "block",
        "meta.class.body.cfml punctuation.section.block.begin.cfml",
        "punctuation.section.block.end.cfml"
    ),
    (
        "group",
        "meta.group.cfml punctuation.section.group.begin.cfml",
        "punctuation.section.group.end.cfml"
    ),
    (
        "brackets",
        "meta.brackets.cfml punctuation.section.brackets.begin.cfml",
        "punctuation.section.brackets.end.cfml"
    ),
    (
        "doc-comment",
        "comment.block.documentation.cfml punctuation.definition.comment.cfml",
        "punctuation.definition.comment.cfml"
    ),
    (
        "block-comment",
        "comment.block.cfml punctuation.definition.comment.cfml",
        "punctuation.definition.comment.cfml"
    ),
    (
        "string-single",
        "meta.string.quoted.single.cfml string.quoted.single.cfml punctuation.definition.string.begin.cfml",
        "punctuation.definition.string.end.cfml"
    ),
    (
        "string-double",
        "meta.string.quoted.double.cfml string.quoted.double.cfml punctuation.definition.string.begin.cfml",
        "punctuation.definition.string.end.cfml"
    ),
    (
        "template-expression",
        "punctuation.definition.template-expression.begin.cfml",
        "punctuation.definition.template-expression.end.cfml"
    ),
    (
        "cftag",
        "punctuation.definition.tag.begin.cfml",
        "punctuation.definition.tag.end.cfml"
    ),
    (
        "cftag-attributes",
        "meta.tag.script.cf.attributes.cfml punctuation.section.group.begin.cfml",
        "punctuation.section.group.end.cfml"
    ),
    (
        "htmltag",
        "punctuation.definition.tag.begin.html",
        "punctuation.definition.tag.end.html"
    )
];
