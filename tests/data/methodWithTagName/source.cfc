//
query
    .where('::some column::', '=', '::some value::')
    .where(
        '::another column::',
        '=',
        '::another value::',
        'or'
    );
