//
{
    {
        getInstance('entityService:Task')
            .list()
            .reduce((result, row) => result.append(row), []);
    }
}
