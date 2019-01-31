extern crate cftokens;

use std::env;
use std::process;

struct DirConfig {
    src_path: String,
    target_path: String,
}

struct FileConfig {
    src_path: String
}

enum Config {
    File(FileConfig),
    Dir(DirConfig)
}

impl Config {
    pub fn new(mut args: std::env::Args) -> Result<Config, &'static str> {
        args.next();

        let src_path = match args.next() {
            Some(arg) => arg,
            None => return Err("Please provide a source path."),
        };

        match args.next() {
            Some(arg) => {
                // we have source and target dir
                let config = DirConfig {
                    src_path,
                    target_path: arg
                };
                Ok(Config::Dir(config))
            },
            None => {
                // with one argument we assume it is a file path
                let config = FileConfig {
                    src_path
                };
                Ok(Config::File(config))
            }
        }
    }
}

fn main() {
    let config = Config::new(env::args()).unwrap_or_else(|err| {
        eprintln!("{}", err);
        process::exit(1);
    });

    let json = match config {
        Config::File(config) => cftokens::tokenize_file(config.src_path),
        Config::Dir(config) => cftokens::tokenize_dir(config.src_path, config.target_path)
    };

    print!("{}", json);
}
