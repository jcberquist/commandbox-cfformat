# commandbox-cfformat

A CommandBox module for formatting CFML components. When installed, it registers a `cfformat` namespace in CommandBox. The base command is `cfformat run` and is called with a path directly to a component, or a path to a directory. When a directory is passed, that directory is crawled for component files, and every component found is formatted.

```bash
cfformat run ./models/MyComponent.cfc
cfformat run ./models/
```

**Important: `commandbox-cfformat` switched from a single `cfformat` command to a `cfformat` namespace in `v0.13.0`. If you have scripts making use of `cfformat`, they will need to be updated.**

If it is passed a component path it will, by default, print the formatted component text to the console. You can redirect this output to a new file if you wish. Alternatively you can use the `--overwrite` flag to overwrite the component in place instead of printing to the console.

When passed a directory, `cfformat run` always overwrites component files in place, and so it will ask for confirmation before proceeding. Here you can use the `--overwrite` flag to skip this confirmation check.

**Note**: `cfformat run` is aliased to `fmt`, so the following syntax can be used as well:

```bash
fmt ./models/MyComponent.cfc
fmt ./models/
```

## Checking Formatting

The `cfformat check` command can be used to determine whether files are formatted according to the currently defined settings. It will report on the status of the file(s) and return an appropriate exit code, without actually formatting them.

```bash
cfformat check ./models/
```

If the `--verbose` flag is specified when running a check, the diff between source files and the formatted versions of those files that fail the check will be printed to the console.

## Watching Directories

`cfformat watch` can also be called with a directory path. It uses CommandBox's built in support for file watching to watch that directory for component changes, and will perform formatting passes on those files.

```bash
cfformat watch ./
```

## Settings

Settings are managed via the `cfformat settings` namespace. To see the settings used for formatting, use the `cfformat settings show` command. It dumps the settings that would be used for formatting to the console:

```bash
cfformat settings show
# or
cfformat settings show /some/path
# or
cfformat settings show path/to/my.cfc /path/to/.cfformat.json
```
The following order is used to resolve the settings used for formatting:

1. Base settings
2. A `.cfformat.json` file in your home directory
3. A `.cfformat.json` file found in the directory where formatting will be performed, or a parent directory thereof. Parent directories will be searched for a `.cfformat.json` file recursively until one is found or the root directory is reached. If a folder contains a `.git` directory that will also halt the search.
4. A path to a settings file passed into the command

These settings will be merged together starting with the base settings and then merging each level on top.

If you want to place a settings file in a directory other than your home directory (for number 2 above) you can set the `cfformat.settings` config setting to a different path:

```bash
config set cfformat.settings=/path/to/.cfformat.json
```

Specifying a settings file to use inline when running `cfformat` is done as follows:

```bash
cfformat run path/to/my.cfc /path/to/.cfformat.json
```

For more information on the settings used and what they do please see the [reference](https://github.com/jcberquist/commandbox-cfformat/blob/master/reference.md). You can also print reference information to the console using the `cfformat settings info` command. It can be passed either a full setting name, or just a prefix:

```bash
cfformat settings info array.padding
cfformat settings info array
```

There is also a settings wizard which can be used to create a `.cfformat.json` file. It walks through all of the settings, showing what each one does, and allowing you to select your preferences (the default for each setting will be preselected). Afterward it will prompt you for a location to save your new settings file.

```bash
cfformat settings wizard
```

## Ignoring Code Sections

Use the special comments `// cfformat-ignore-start` and `// cfformat-ignore-end` (or the equivalent block comment or tag comment syntax) to have `cfformat` return the contained code as is without formatting it:

```cfc
// cfformat-ignore-start
test = [1,2,3,4,5,6,7,8];
// cfformat-ignore-end
```

**Note**: When doing this it is important to keep your start and end comment flags at the same level of the file. In other words, the following will not work:

```cfc
// cfformat-ignore-start
if (true) {
    ...
    // cfformat-ignore-end
}
```
## Checking Tag structure

The `cfformat tag-check` command is a utilty command that will check a file or directory of files for tags that are unbalanced or incorrectly structured. When it finds such tags, it will report on the the files and line numbers for you.

```bash
cfformat tag-check ./views/
```

If the `--verbose` flag is specified when running a check, the diff between source files and the formatted versions of those files that fail the check will be printed to the console.

## Syntect

Behind the scenes, `cfformat` makes use of the [cftokens](https://github.com/jcberquist/cftokens) project, which is based on the [syntect](https://github.com/trishume/syntect) library along with syntax files from Sublime Text's [Packages](https://github.com/sublimehq/Packages). `cfformat` attempts to download this executable from GitHub when installed, or when it is updated (if necessary). If it is unable to download the executable, it should print a message to the console prompting you to download from GitHub, and indicating where to put it.
