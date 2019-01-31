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
```

If you want to overwrite the default settings, you can create a JSON file with your overrides, save it in a convenient place, and set the path to it in the CommandBox config:

```bash
cfformat --settings > /path/to/settings.json
# edit those settings
# Note: the settings are merged with the defaults
# so your override file does not need to keep any
# settings that match the default settings
config set cfformat.settings=/path/to/settings.json
```

You can also specify a settings file to use inline when running `cfformat`:

```bash
cfformat path/to/my.cfc path/to/settings.json
```

_Note: The settings printed to the console via the `--settings` flag are the final settings that will be used after merging together the settings sources. Warning: how settings are handled is subject to change._

## Syntect

Behind the scenes, `cfformat` makes use of the [syntect](https://github.com/trishume/syntect) library along with syntax files from Sublime Text's [Packages](https://github.com/sublimehq/Packages) repository to create an executable that uses the CFML syntax for Sublime Text to generate syntax scopes for component files. `cfformat` attempts to download this executable from GitHub when installed, or when it is updated (if necessary). If it is unable to download the executable, it should print a message to the console prompting you to download from GitHub, and indicating where to put it. If you have Rust installed, you can also build the executable yourself by running the `build.cfc` task runner in the root of this repository:

```bash
task run build.cfc
```
