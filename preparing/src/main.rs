mod database;
mod generator;

use std::error::Error;
use std::path::PathBuf;

fn main() -> Result<(), Box<dyn Error>> {
        let manifest_directory = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        let resource_directory = manifest_directory.join("res");
        let output_directory = manifest_directory.join("../entry/src/main/resources/resfile");
        let app_path = output_directory.join("app.sqlite3");
        let ime_path = output_directory.join("ime.sqlite3");

        generator::generate_app(&resource_directory, &app_path)?;
        println!("Created {}", app_path.canonicalize()?.display());
        generator::generate_ime(&resource_directory, &ime_path)?;
        println!("Created {}", ime_path.canonicalize()?.display());
        Ok(())
}
