extern crate syntect;
extern crate cftokens;

use std::env;
use std::process;
use syntect::parsing::SyntaxSet;

struct DirConfig {
    src_path: String,
    target_path: String,
}

struct FileConfig {
    src_path: String
}

struct ManifestConfig {
    src_path: String
}

enum Config {
    File(FileConfig),
    Dir(DirConfig),
    Manifest(ManifestConfig)
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
                if src_path.ends_with(".cfc") {
                    let config = FileConfig {
                        src_path
                    };
                    Ok(Config::File(config))
                } else {
                    let config = ManifestConfig {
                        src_path
                    };
                    Ok(Config::Manifest(config))
                }


            }
        }
    }
}

fn main() {
    let config = Config::new(env::args()).unwrap_or_else(|err| {
        eprintln!("{}", err);
        process::exit(1);
    });

    let ss = SyntaxSet::load_defaults_newlines();

    let json = match config {
        Config::File(config) => cftokens::tokenize_file(&ss, config.src_path),
        Config::Dir(config) => cftokens::tokenize_dir(&ss, config.src_path, config.target_path),
        Config::Manifest(config) => cftokens::tokenize_manifest(&ss, config.src_path),
    };

    print!("{}", json);
}
