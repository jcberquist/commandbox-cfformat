# commandbox-cfformat

This module registers a `cfformat` command in CommandBox that can be used to format CFML components. It is called with a path directly to a component, or a path to a directory. When a directory is passed, that directory is crawled for component files, and every component found is formatted.

```bash
cfformat ./models/MyComponent.cfc
cfformat ./models/
```

If it is passed a component path it will, by default, print the formatted component text to the console. You can redirect this output to a new file if you wish. Alternatively you can use the `--overwrite` flag to overwrite the component in place instead of printing to the console.

When passed a directory, `cfformat` always overwrites component files in place, and so it will ask for confirmation before proceeding. Here you can use the `--overwrite` flag to skip this confirmation check.

## Settings

To see the settings used for formatting, use the `--settings` flag. When that is present the `cfformat` command will just dump to the console the settings it will use to format, and not perform any formatting:

```bash
cfformat --settings
# or
cfformat /some/path --settings
# or
cfformat path/to/my.cfc /path/to/.cfformat.json --settings
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
cfformat path/to/my.cfc /path/to/.cfformat.json
```

## Syntect

Behind the scenes, `cfformat` makes use of the [syntect](https://github.com/trishume/syntect) library along with syntax files from Sublime Text's [Packages](https://github.com/sublimehq/Packages) repository to create an executable that uses the CFML syntax for Sublime Text to generate syntax scopes for component files. `cfformat` attempts to download this executable from GitHub when installed, or when it is updated (if necessary). If it is unable to download the executable, it should print a message to the console prompting you to download from GitHub, and indicating where to put it. If you have Rust installed, you can also build the executable yourself by running the `build.cfc` task runner in the root of this repository:

```bash
task run build.cfc
```
