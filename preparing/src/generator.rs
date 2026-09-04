use crate::database::Database;
use std::collections::{BTreeMap, HashMap, HashSet};
use std::error::Error;
use std::fs;
use std::io;
use std::path::{Path, PathBuf};

type Result<T> = std::result::Result<T, Box<dyn Error>>;

const APP_INDEXES: &[&str] = &[
        "CREATE INDEX ix_jyutping_word ON jyutping_table (word)",
        "CREATE INDEX ix_jyutping_romanization ON jyutping_table (romanization)",
        "CREATE INDEX ix_collocation_unified ON collocation_table (word, romanization)",
        "CREATE INDEX ix_dictionary_unified ON dictionary_table (word, romanization)",
        "CREATE INDEX ix_yingwaa_code ON yingwaa_table (code)",
        "CREATE INDEX ix_yingwaa_romanization ON yingwaa_table (romanization)",
        "CREATE INDEX ix_chohok_code ON chohok_table (code)",
        "CREATE INDEX ix_chohok_romanization ON chohok_table (romanization)",
        "CREATE INDEX ix_fanwan_code ON fanwan_table (code)",
        "CREATE INDEX ix_fanwan_romanization ON fanwan_table (romanization)",
        "CREATE INDEX ix_gwongwan_code ON gwongwan_table (code)",
];

const IME_TABLES: &[&str] = &[
        "CREATE TABLE lexicon_core (id INTEGER PRIMARY KEY AUTOINCREMENT, word TEXT NOT NULL, romanization TEXT NOT NULL, char_count INTEGER NOT NULL, complexity INTEGER NOT NULL, anchors INTEGER NOT NULL, spell INTEGER NOT NULL, anchors_9key INTEGER NOT NULL, spell_9key INTEGER NOT NULL)",
        "CREATE TABLE structure_table (id INTEGER PRIMARY KEY AUTOINCREMENT, word TEXT NOT NULL, romanization TEXT NOT NULL, char_count INTEGER NOT NULL, complexity INTEGER NOT NULL, spell INTEGER NOT NULL, spell_9key INTEGER NOT NULL)",
        "CREATE TABLE pinyin_lexicon (id INTEGER PRIMARY KEY AUTOINCREMENT, word TEXT NOT NULL, romanization TEXT NOT NULL, char_count INTEGER NOT NULL, complexity INTEGER NOT NULL, anchors INTEGER NOT NULL, spell INTEGER NOT NULL, anchors_9key INTEGER NOT NULL, spell_9key INTEGER NOT NULL)",
        "CREATE TABLE cangjie_table (id INTEGER PRIMARY KEY AUTOINCREMENT, word TEXT NOT NULL, cangjie5 TEXT NOT NULL, c5complex INTEGER NOT NULL, c5code INTEGER NOT NULL, cangjie3 TEXT NOT NULL, c3complex INTEGER NOT NULL, c3code INTEGER NOT NULL)",
        "CREATE TABLE quick_table (id INTEGER PRIMARY KEY AUTOINCREMENT, word TEXT NOT NULL, quick5 TEXT NOT NULL, q5complex INTEGER NOT NULL, q5code INTEGER NOT NULL, quick3 TEXT NOT NULL, q3complex INTEGER NOT NULL, q3code INTEGER NOT NULL)",
        "CREATE TABLE stroke_table (id INTEGER PRIMARY KEY AUTOINCREMENT, word TEXT NOT NULL, stroke TEXT NOT NULL, complex INTEGER NOT NULL, code INTEGER NOT NULL)",
        "CREATE TABLE symbol_table (id INTEGER PRIMARY KEY AUTOINCREMENT, category INTEGER NOT NULL, unicode_version INTEGER NOT NULL, code_point TEXT NOT NULL, cantonese TEXT NOT NULL, romanization TEXT NOT NULL, complexity INTEGER NOT NULL, spell INTEGER NOT NULL, spell_9key INTEGER NOT NULL)",
        "CREATE TABLE emoji_skin_map (id INTEGER PRIMARY KEY AUTOINCREMENT, source TEXT NOT NULL, target TEXT NOT NULL)",
        "CREATE TABLE plain_text_table (id INTEGER PRIMARY KEY AUTOINCREMENT, input TEXT NOT NULL, word TEXT NOT NULL, letter_count INTEGER NOT NULL, spell INTEGER NOT NULL, spell_9key INTEGER NOT NULL)",
        "CREATE TABLE syllable_core_table (alias_code INTEGER PRIMARY KEY, origin_code INTEGER NOT NULL, alias TEXT NOT NULL, origin TEXT NOT NULL)",
        "CREATE TABLE syllable_9key_table (alias_code INTEGER PRIMARY KEY, origin_code INTEGER NOT NULL, alias_9key_code INTEGER NOT NULL, origin_9key_code INTEGER NOT NULL, alias TEXT NOT NULL, origin TEXT NOT NULL)",
        "CREATE TABLE syllable_pinyin_table (code INTEGER PRIMARY KEY, code_9key INTEGER NOT NULL, syllable TEXT NOT NULL)",
        "CREATE TABLE variant_abp (source INTEGER PRIMARY KEY, target INTEGER NOT NULL)",
        "CREATE TABLE variant_hk (source INTEGER PRIMARY KEY, target INTEGER NOT NULL)",
        "CREATE TABLE variant_old (source INTEGER PRIMARY KEY, target INTEGER NOT NULL)",
        "CREATE TABLE variant_prc (source INTEGER PRIMARY KEY, target INTEGER NOT NULL)",
        "CREATE TABLE variant_sim (source INTEGER PRIMARY KEY, target INTEGER NOT NULL)",
        "CREATE TABLE variant_tw (source INTEGER PRIMARY KEY, target INTEGER NOT NULL)",
];

const IME_INDEXES: &[&str] = &[
        "CREATE INDEX ix_lexicon_core_anchors ON lexicon_core (anchors, char_count)",
        "CREATE INDEX ix_lexicon_core_spell ON lexicon_core (spell, complexity)",
        "CREATE INDEX ix_lexicon_core_anchors_9key ON lexicon_core (anchors_9key, char_count)",
        "CREATE INDEX ix_lexicon_core_spell_9key ON lexicon_core (spell_9key, complexity)",
        "CREATE INDEX ix_lexicon_core_word ON lexicon_core (word)",
        "CREATE INDEX ix_structure_spell ON structure_table (spell, complexity)",
        "CREATE INDEX ix_structure_spell_9key ON structure_table (spell_9key, complexity)",
        "CREATE INDEX ix_pinyin_anchors ON pinyin_lexicon (anchors, char_count)",
        "CREATE INDEX ix_pinyin_spell ON pinyin_lexicon (spell, complexity)",
        "CREATE INDEX ix_pinyin_anchors_9key ON pinyin_lexicon (anchors_9key, char_count)",
        "CREATE INDEX ix_pinyin_spell_9key ON pinyin_lexicon (spell_9key, complexity)",
        "CREATE INDEX ix_cangjie_cangjie5 ON cangjie_table (cangjie5, c5complex)",
        "CREATE INDEX ix_cangjie_c5code ON cangjie_table (c5code)",
        "CREATE INDEX ix_cangjie_cangjie3 ON cangjie_table (cangjie3, c3complex)",
        "CREATE INDEX ix_cangjie_c3code ON cangjie_table (c3code)",
        "CREATE INDEX ix_quick_quick5 ON quick_table (quick5, q5complex)",
        "CREATE INDEX ix_quick_q5code ON quick_table (q5code)",
        "CREATE INDEX ix_quick_quick3 ON quick_table (quick3, q3complex)",
        "CREATE INDEX ix_quick_q3code ON quick_table (q3code)",
        "CREATE INDEX ix_stroke_stroke ON stroke_table (stroke, complex)",
        "CREATE INDEX ix_stroke_code ON stroke_table (code, complex)",
        "CREATE INDEX ix_symbol_spell ON symbol_table (spell, complexity)",
        "CREATE INDEX ix_symbol_spell_9key ON symbol_table (spell_9key, complexity)",
        "CREATE INDEX ix_emoji_skin_map_source ON emoji_skin_map (source)",
        "CREATE INDEX ix_plain_text_spell ON plain_text_table (spell, letter_count)",
        "CREATE INDEX ix_plain_text_spell_9key ON plain_text_table (spell_9key, letter_count)",
];

const VARIANT_TABLES: &[(&str, &str)] = &[
        ("CharacterVariant.AncientBooksPublishing.txt", "variant_abp"),
        ("CharacterVariant.HongKong.txt", "variant_hk"),
        ("CharacterVariant.Inherited.txt", "variant_old"),
        ("CharacterVariant.PRCGeneral.txt", "variant_prc"),
        ("CharacterVariant.Simplified.txt", "variant_sim"),
        ("CharacterVariant.Taiwan.txt", "variant_tw"),
];

#[derive(Clone, Debug, Eq, Hash, PartialEq)]
struct LexiconEntry {
        word: String,
        romanization: String,
        char_count: i64,
        complexity: i64,
        anchors: i64,
        spell: i64,
        anchors_9key: i64,
        spell_9key: i64,
}

#[derive(Clone, Debug, Eq, Hash, PartialEq)]
struct CangjieEntry {
        word: String,
        cangjie5: String,
        c5complex: i64,
        c5code: i64,
        cangjie3: String,
        c3complex: i64,
        c3code: i64,
}

#[derive(Clone, Debug, Eq, Hash, PartialEq)]
struct QuickEntry {
        word: String,
        quick5: String,
        q5complex: i64,
        q5code: i64,
        quick3: String,
        q3complex: i64,
        q3code: i64,
}

#[derive(Clone, Debug, Eq, Hash, PartialEq)]
struct StrokeEntry {
        word: String,
        stroke: String,
        complex: i64,
        code: i64,
}

pub fn generate_app(resource_directory: &Path, output_path: &Path) -> Result<()> {
        generate_database(output_path, |database| {
                insert_app_jyutping(database, resource_directory)?;
                insert_tabular_app_table(
                        database,
                        resource_directory,
                        "collocation.txt",
                        3,
                        "CREATE TABLE collocation_table (id INTEGER PRIMARY KEY AUTOINCREMENT, word TEXT NOT NULL, romanization TEXT NOT NULL, collocation TEXT NOT NULL, UNIQUE (word, romanization))",
                        "INSERT INTO collocation_table (word, romanization, collocation) VALUES (?, ?, ?)",
                )?;
                insert_tabular_app_table(
                        database,
                        resource_directory,
                        "wordshk.txt",
                        3,
                        "CREATE TABLE dictionary_table (id INTEGER PRIMARY KEY AUTOINCREMENT, word TEXT NOT NULL, romanization TEXT NOT NULL, description TEXT NOT NULL)",
                        "INSERT INTO dictionary_table (word, romanization, description) VALUES (?, ?, ?)",
                )?;
                insert_yingwaa(database, resource_directory)?;
                insert_chohok(database, resource_directory)?;
                insert_fanwan(database, resource_directory)?;
                insert_gwongwan(database, resource_directory)?;
                insert_definitions(database, resource_directory)?;
                execute_all(database, APP_INDEXES)
        })
}

pub fn generate_ime(resource_directory: &Path, output_path: &Path) -> Result<()> {
        generate_database(output_path, |database| {
                execute_all(database, IME_TABLES)?;
                let jyutping_lines = nonempty_source_lines(resource_directory, "jyutping.txt")?;
                let jyutping = convert_lexicon(&jyutping_lines, "jyutping.txt")?;
                insert_lexicon(database, "lexicon_core", &jyutping)?;
                insert_structure(database, resource_directory)?;
                insert_pinyin(database, resource_directory)?;
                let cangjie5 = source_map(resource_directory, "cangjie5.txt")?;
                let cangjie3 = source_map(resource_directory, "cangjie3.txt")?;
                insert_cangjie(database, &jyutping_lines, &cangjie5, &cangjie3)?;
                insert_quick(database, &jyutping_lines, &cangjie5, &cangjie3)?;
                insert_strokes(database, resource_directory, &jyutping_lines)?;
                insert_symbols(database, resource_directory)?;
                insert_skin_tone_map(database, resource_directory)?;
                insert_plain_text(database, resource_directory)?;
                insert_syllables(database, resource_directory)?;
                insert_variants(database, resource_directory)?;
                execute_all(database, IME_INDEXES)
        })
}

fn insert_app_jyutping(database: &Database, resource_directory: &Path) -> Result<()> {
        database.execute("CREATE TABLE jyutping_table (id INTEGER PRIMARY KEY AUTOINCREMENT, word TEXT NOT NULL, romanization TEXT NOT NULL)")?;
        let mut statement = database.prepare("INSERT INTO jyutping_table (word, romanization) VALUES (?, ?)")?;
        for line in nonempty_source_lines(resource_directory, "jyutping.txt")? {
                let parts = exact_fields(&line, '\t', 2, "jyutping.txt")?;
                statement.bind_text(1, parts[0])?;
                statement.bind_text(2, parts[1])?;
                statement.insert()?;
        }
        Ok(())
}

fn insert_tabular_app_table(database: &Database, resource_directory: &Path, file_name: &str, field_count: usize, create_sql: &str, insert_sql: &str) -> Result<()> {
        database.execute(create_sql)?;
        let mut statement = database.prepare(insert_sql)?;
        for line in nonempty_source_lines(resource_directory, file_name)? {
                let parts = exact_fields(&line, '\t', field_count, file_name)?;
                for (index, value) in parts.iter().enumerate() {
                        statement.bind_text(i32::try_from(index + 1)?, value)?;
                }
                statement.insert()?;
        }
        Ok(())
}

fn insert_yingwaa(database: &Database, resource_directory: &Path) -> Result<()> {
        database.execute("CREATE TABLE yingwaa_table(code INTEGER NOT NULL, word TEXT NOT NULL, romanization TEXT NOT NULL, pronunciation TEXT NOT NULL, note TEXT NOT NULL, interpretation TEXT NOT NULL)")?;
        let mut statement = database.prepare("INSERT INTO yingwaa_table (code, word, romanization, pronunciation, note, interpretation) VALUES (?, ?, ?, ?, ?, ?)")?;
        for line in nonempty_source_lines(resource_directory, "yingwaa.txt")? {
                let parts = exact_fields(&line, '\t', 5, "yingwaa.txt")?;
                statement.bind_i64(1, first_code_point(parts[0], "yingwaa.txt")?)?;
                bind_texts(&mut statement, 2, &parts)?;
                statement.insert()?;
        }
        Ok(())
}

fn insert_chohok(database: &Database, resource_directory: &Path) -> Result<()> {
        database.execute(
                "CREATE TABLE chohok_table(code INTEGER NOT NULL, word TEXT NOT NULL, romanization TEXT NOT NULL, phone TEXT NOT NULL, tone TEXT NOT NULL, faancit TEXT NOT NULL)",
        )?;
        let mut statement = database.prepare("INSERT INTO chohok_table (code, word, romanization, phone, tone, faancit) VALUES (?, ?, ?, ?, ?, ?)")?;
        for line in nonempty_source_lines(resource_directory, "chohok.txt")? {
                let parts = exact_fields(&line, '\t', 5, "chohok.txt")?;
                statement.bind_i64(1, first_code_point(parts[0], "chohok.txt")?)?;
                bind_texts(&mut statement, 2, &parts)?;
                statement.insert()?;
        }
        Ok(())
}

fn insert_fanwan(database: &Database, resource_directory: &Path) -> Result<()> {
        database.execute("CREATE TABLE fanwan_table(code INTEGER NOT NULL, word TEXT NOT NULL, romanization TEXT NOT NULL, initial TEXT NOT NULL, final TEXT NOT NULL, yamyeung TEXT NOT NULL, tone TEXT NOT NULL, rhyme TEXT NOT NULL, interpretation TEXT NOT NULL)")?;
        let mut statement =
                database.prepare("INSERT INTO fanwan_table (code, word, romanization, initial, final, yamyeung, tone, rhyme, interpretation) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)")?;
        for line in nonempty_source_lines(resource_directory, "fanwan.txt")? {
                let parts = exact_fields(&line, '\t', 8, "fanwan.txt")?;
                statement.bind_i64(1, first_code_point(parts[0], "fanwan.txt")?)?;
                bind_texts(&mut statement, 2, &parts)?;
                statement.insert()?;
        }
        Ok(())
}

fn insert_gwongwan(database: &Database, resource_directory: &Path) -> Result<()> {
        database.execute("CREATE TABLE gwongwan_table(code INTEGER NOT NULL, word TEXT NOT NULL, rhyme TEXT NOT NULL, subrhyme TEXT NOT NULL, subrhymeserial INTEGER NOT NULL, subrhymenumber INTEGER NOT NULL, upper TEXT NOT NULL, lower TEXT NOT NULL, initial TEXT NOT NULL, rounding TEXT NOT NULL, division TEXT NOT NULL, rhymeclass TEXT NOT NULL, repeating TEXT NOT NULL, tone TEXT NOT NULL, interpretation TEXT NOT NULL)")?;
        let mut statement = database.prepare("INSERT INTO gwongwan_table (code, word, rhyme, subrhyme, subrhymeserial, subrhymenumber, upper, lower, initial, rounding, division, rhymeclass, repeating, tone, interpretation) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)")?;
        for line in nonempty_source_lines(resource_directory, "gwongwan.txt")? {
                let parts = exact_fields(&line, ',', 14, "gwongwan.txt")?;
                statement.bind_i64(1, first_code_point(parts[0], "gwongwan.txt")?)?;
                statement.bind_text(2, parts[0])?;
                statement.bind_text(3, parts[1])?;
                statement.bind_text(4, parts[2])?;
                statement.bind_i64(5, parts[3].parse()?)?;
                statement.bind_i64(6, parts[4].parse()?)?;
                for (index, value) in parts[5..].iter().enumerate() {
                        statement.bind_text(i32::try_from(index + 7)?, value)?;
                }
                statement.insert()?;
        }
        Ok(())
}

fn insert_definitions(database: &Database, resource_directory: &Path) -> Result<()> {
        database.execute("CREATE TABLE definition_table (code INTEGER PRIMARY KEY, definition TEXT NOT NULL)")?;
        let definitions = definition_map(resource_directory)?;
        let jyutping_lines = nonempty_source_lines(resource_directory, "jyutping.txt")?;
        let mut statement = database.prepare("INSERT INTO definition_table (code, definition) VALUES (?, ?)")?;
        for word in jyutping_words(&jyutping_lines, true) {
                let Some(definition) = definitions.get(&word) else {
                        continue;
                };
                statement.bind_i64(1, first_code_point(&word, "jyutping.txt")?)?;
                statement.bind_text(2, definition)?;
                statement.insert()?;
        }
        Ok(())
}

fn insert_lexicon(database: &Database, table: &str, entries: &[LexiconEntry]) -> Result<()> {
        let sql = format!("INSERT INTO {table} (word, romanization, char_count, complexity, anchors, spell, anchors_9key, spell_9key) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
        let mut statement = database.prepare(&sql)?;
        for entry in entries {
                statement.bind_text(1, &entry.word)?;
                statement.bind_text(2, &entry.romanization)?;
                statement.bind_i64(3, entry.char_count)?;
                statement.bind_i64(4, entry.complexity)?;
                statement.bind_i64(5, entry.anchors)?;
                statement.bind_i64(6, entry.spell)?;
                statement.bind_i64(7, entry.anchors_9key)?;
                statement.bind_i64(8, entry.spell_9key)?;
                statement.insert()?;
        }
        Ok(())
}

fn insert_structure(database: &Database, resource_directory: &Path) -> Result<()> {
        let mut transformed = Vec::new();
        let mut seen = HashSet::new();
        for line in source_lines(resource_directory, "structure.txt")? {
                let parts = exact_fields(&line, '\t', 3, "structure.txt")?;
                let value = format!("{}\t{}", parts[0], parts[2]);
                if seen.insert(value.clone()) {
                        transformed.push(value);
                }
        }
        let entries = convert_lexicon(&transformed, "structure.txt")?;
        let mut statement = database.prepare("INSERT INTO structure_table (word, romanization, char_count, complexity, spell, spell_9key) VALUES (?, ?, ?, ?, ?, ?)")?;
        for entry in entries {
                statement.bind_text(1, &entry.word)?;
                statement.bind_text(2, &entry.romanization)?;
                statement.bind_i64(3, entry.char_count)?;
                statement.bind_i64(4, entry.complexity)?;
                statement.bind_i64(5, entry.spell)?;
                statement.bind_i64(6, entry.spell_9key)?;
                statement.insert()?;
        }
        Ok(())
}

fn insert_pinyin(database: &Database, resource_directory: &Path) -> Result<()> {
        let lines = nonempty_source_lines(resource_directory, "pinyin.txt")?;
        let entries = convert_lexicon(&lines, "pinyin.txt")?;
        insert_lexicon(database, "pinyin_lexicon", &entries)
}

fn insert_cangjie(database: &Database, jyutping_lines: &[String], cangjie5: &HashMap<String, Vec<String>>, cangjie3: &HashMap<String, Vec<String>>) -> Result<()> {
        let mut entries = Vec::new();
        let mut seen = HashSet::new();
        for word in jyutping_words(jyutping_lines, true) {
                let matches5 = cangjie5.get(&word).map(Vec::as_slice).unwrap_or_default();
                let matches3 = cangjie3.get(&word).map(Vec::as_slice).unwrap_or_default();
                for index in 0..matches5.len().max(matches3.len()) {
                        let code5 = matches5.get(index).map(String::as_str).unwrap_or("X");
                        let code3 = matches3.get(index).map(String::as_str).unwrap_or("X");
                        let entry = CangjieEntry {
                                word: word.clone(),
                                cangjie5: code5.to_owned(),
                                c5complex: character_count(code5),
                                c5code: serial_code(code5),
                                cangjie3: code3.to_owned(),
                                c3complex: character_count(code3),
                                c3code: serial_code(code3),
                        };
                        if seen.insert(entry.clone()) {
                                entries.push(entry);
                        }
                }
        }
        let mut statement = database.prepare("INSERT INTO cangjie_table (word, cangjie5, c5complex, c5code, cangjie3, c3complex, c3code) VALUES (?, ?, ?, ?, ?, ?, ?)")?;
        for entry in entries {
                statement.bind_text(1, &entry.word)?;
                statement.bind_text(2, &entry.cangjie5)?;
                statement.bind_i64(3, entry.c5complex)?;
                statement.bind_i64(4, entry.c5code)?;
                statement.bind_text(5, &entry.cangjie3)?;
                statement.bind_i64(6, entry.c3complex)?;
                statement.bind_i64(7, entry.c3code)?;
                statement.insert()?;
        }
        Ok(())
}

fn insert_quick(database: &Database, jyutping_lines: &[String], cangjie5: &HashMap<String, Vec<String>>, cangjie3: &HashMap<String, Vec<String>>) -> Result<()> {
        let mut entries = Vec::new();
        let mut seen = HashSet::new();
        for word in jyutping_words(jyutping_lines, false) {
                if character_count(&word) == 1 {
                        let matches5 = cangjie5.get(&word).map(Vec::as_slice).unwrap_or_default();
                        let matches3 = cangjie3.get(&word).map(Vec::as_slice).unwrap_or_default();
                        for index in 0..matches5.len().max(matches3.len()) {
                                let quick5 = quick_code(matches5.get(index).map(String::as_str).unwrap_or("X"));
                                let quick3 = quick_code(matches3.get(index).map(String::as_str).unwrap_or("X"));
                                push_quick_entry(&mut entries, &mut seen, &word, quick5, quick3);
                        }
                } else {
                        let quick5 = word.chars().map(|character| first_quick_code(cangjie5, character)).collect::<Vec<_>>().concat();
                        let quick3 = word.chars().map(|character| first_quick_code(cangjie3, character)).collect::<Vec<_>>().concat();
                        push_quick_entry(&mut entries, &mut seen, &word, quick5, quick3);
                }
        }
        let mut statement = database.prepare("INSERT INTO quick_table (word, quick5, q5complex, q5code, quick3, q3complex, q3code) VALUES (?, ?, ?, ?, ?, ?, ?)")?;
        for entry in entries {
                statement.bind_text(1, &entry.word)?;
                statement.bind_text(2, &entry.quick5)?;
                statement.bind_i64(3, entry.q5complex)?;
                statement.bind_i64(4, entry.q5code)?;
                statement.bind_text(5, &entry.quick3)?;
                statement.bind_i64(6, entry.q3complex)?;
                statement.bind_i64(7, entry.q3code)?;
                statement.insert()?;
        }
        Ok(())
}

fn insert_strokes(database: &Database, resource_directory: &Path, jyutping_lines: &[String]) -> Result<()> {
        let stroke_map = source_map(resource_directory, "stroke.txt")?;
        let mut entries = Vec::new();
        let mut seen = HashSet::new();
        for word in jyutping_words(jyutping_lines, true) {
                let Some(matches) = stroke_map.get(&word) else {
                        continue;
                };
                for matched in matches {
                        let mut codes = Vec::new();
                        for character in matched.chars() {
                                let code = match character {
                                        'w' | 'h' | '1' => 1,
                                        's' | '2' => 2,
                                        'a' | 'p' | '3' => 3,
                                        'd' | 'n' | '4' => 4,
                                        'z' | '5' => 5,
                                        _ => return invalid_data(format!("bad stroke format: {word} = {matched}")),
                                };
                                codes.push(code);
                        }
                        if codes.len() > 30 {
                                continue;
                        }
                        let stroke = codes.iter().map(i64::to_string).collect::<String>();
                        let entry = StrokeEntry { word: word.clone(), stroke, complex: i64::try_from(codes.len())?, code: decimal_code(codes) };
                        if seen.insert((entry.word.clone(), entry.stroke.clone())) {
                                entries.push(entry);
                        }
                }
        }
        let mut statement = database.prepare("INSERT INTO stroke_table (word, stroke, complex, code) VALUES (?, ?, ?, ?)")?;
        for entry in entries {
                statement.bind_text(1, &entry.word)?;
                statement.bind_text(2, &entry.stroke)?;
                statement.bind_i64(3, entry.complex)?;
                statement.bind_i64(4, entry.code)?;
                statement.insert()?;
        }
        Ok(())
}

fn insert_symbols(database: &Database, resource_directory: &Path) -> Result<()> {
        let mut statement = database.prepare(
                "INSERT INTO symbol_table (category, unicode_version, code_point, cantonese, romanization, complexity, spell, spell_9key) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        )?;
        for line in source_lines(resource_directory, "symbol.txt")? {
                let parts = split_fields(&line, '\t');
                if parts.len() != 5 {
                        continue;
                }
                let romanization = parts[4];
                let complexity = decimal_code(romanization.split(' ').filter(|phone| !phone.is_empty()).map(|phone| character_count(phone) - 1));
                statement.bind_i64(1, parts[0].parse()?)?;
                statement.bind_i64(2, parts[1].parse()?)?;
                statement.bind_text(3, parts[2])?;
                statement.bind_text(4, parts[3])?;
                statement.bind_text(5, romanization)?;
                statement.bind_i64(6, complexity)?;
                statement.bind_i64(7, serial_code(romanization))?;
                statement.bind_i64(8, keypad_code(romanization))?;
                statement.insert()?;
        }
        Ok(())
}

fn insert_skin_tone_map(database: &Database, resource_directory: &Path) -> Result<()> {
        let mut statement = database.prepare("INSERT INTO emoji_skin_map (source, target) VALUES (?, ?)")?;
        for line in source_lines(resource_directory, "skin-tone-map.txt")? {
                let parts = split_fields(&line, '\t');
                if parts.len() != 2 {
                        continue;
                }
                statement.bind_text(1, parts[0])?;
                statement.bind_text(2, parts[1])?;
                statement.insert()?;
        }
        Ok(())
}

fn insert_plain_text(database: &Database, resource_directory: &Path) -> Result<()> {
        let mut seen_lines = HashSet::new();
        let mut seen_entries = HashSet::new();
        let mut statement = database.prepare("INSERT INTO plain_text_table (input, word, letter_count, spell, spell_9key) VALUES (?, ?, ?, ?, ?)")?;
        for source_line in source_lines(resource_directory, "text.txt")? {
                let line = source_line.trim();
                if line.is_empty() || line.starts_with('#') || !seen_lines.insert(line.to_owned()) {
                        continue;
                }
                let parts = split_fields(line, '\t');
                if parts.len() < 2 {
                        return invalid_data(format!("bad line format in text.txt: {line}"));
                }
                let input = parts[0];
                let word = parts[1];
                if !seen_entries.insert((input.to_owned(), word.to_owned())) {
                        continue;
                }
                statement.bind_text(1, input)?;
                statement.bind_text(2, word)?;
                statement.bind_i64(3, character_count(input))?;
                statement.bind_i64(4, serial_code(input))?;
                statement.bind_i64(5, keypad_code(input))?;
                statement.insert()?;
        }
        Ok(())
}

fn insert_syllables(database: &Database, resource_directory: &Path) -> Result<()> {
        let mut core_statement = database.prepare("INSERT INTO syllable_core_table (alias_code, origin_code, alias, origin) VALUES (?, ?, ?, ?)")?;
        for (alias, origin) in syllable_pairs(resource_directory, "syllable-core.txt")? {
                core_statement.bind_i64(1, serial_code(&alias))?;
                core_statement.bind_i64(2, serial_code(&origin))?;
                core_statement.bind_text(3, &alias)?;
                core_statement.bind_text(4, &origin)?;
                core_statement.insert()?;
        }

        let mut nine_key_statement =
                database.prepare("INSERT INTO syllable_9key_table (alias_code, origin_code, alias_9key_code, origin_9key_code, alias, origin) VALUES (?, ?, ?, ?, ?, ?)")?;
        for (alias, origin) in syllable_pairs(resource_directory, "syllable-9key.txt")? {
                nine_key_statement.bind_i64(1, serial_code(&alias))?;
                nine_key_statement.bind_i64(2, serial_code(&origin))?;
                nine_key_statement.bind_i64(3, keypad_code(&alias))?;
                nine_key_statement.bind_i64(4, keypad_code(&origin))?;
                nine_key_statement.bind_text(5, &alias)?;
                nine_key_statement.bind_text(6, &origin)?;
                nine_key_statement.insert()?;
        }

        let mut pinyin_statement = database.prepare("INSERT INTO syllable_pinyin_table (code, code_9key, syllable) VALUES (?, ?, ?)")?;
        for syllable in nonempty_source_lines(resource_directory, "syllable-pinyin.txt")? {
                let syllable = syllable.trim();
                pinyin_statement.bind_i64(1, serial_code(syllable))?;
                pinyin_statement.bind_i64(2, keypad_code(syllable))?;
                pinyin_statement.bind_text(3, syllable)?;
                pinyin_statement.insert()?;
        }
        Ok(())
}

fn insert_variants(database: &Database, resource_directory: &Path) -> Result<()> {
        for (file_name, table_name) in VARIANT_TABLES {
                let variants = character_variants(resource_directory, file_name)?;
                let sql = format!("INSERT INTO {table_name} (source, target) VALUES (?, ?)");
                let mut statement = database.prepare(&sql)?;
                for (source, target) in variants {
                        statement.bind_i64(1, i64::from(source))?;
                        statement.bind_i64(2, i64::from(target))?;
                        statement.insert()?;
                }
        }
        Ok(())
}

fn convert_lexicon(lines: &[String], file_name: &str) -> Result<Vec<LexiconEntry>> {
        let mut entries = Vec::with_capacity(lines.len());
        for line in lines {
                let parts = line.trim().split('\t').map(str::trim).collect::<Vec<_>>();
                if parts.len() != 2 {
                        return invalid_data(format!("bad line format in {file_name}: {line}"));
                }
                let word = parts[0];
                let romanization = parts[1];
                let without_tones = romanization.chars().filter(|character| !character.is_ascii_digit()).collect::<String>();
                let phones = without_tones.split(' ').filter(|phone| !phone.is_empty()).collect::<Vec<_>>();
                let complexity = decimal_code(phones.iter().map(|phone| character_count(phone)));
                let anchors = phones.iter().filter_map(|phone| phone.chars().next()).collect::<String>();
                let letters = romanization.chars().filter(char::is_ascii_lowercase).collect::<String>();
                if letters.is_empty() {
                        return invalid_data(format!("bad line format in {file_name}: {line}"));
                }
                entries.push(LexiconEntry {
                        word: word.to_owned(),
                        romanization: romanization.to_owned(),
                        char_count: character_count(word),
                        complexity,
                        anchors: serial_code(&anchors),
                        spell: serial_code(&letters),
                        anchors_9key: keypad_code(&anchors),
                        spell_9key: keypad_code(&letters),
                });
        }
        Ok(entries)
}

fn source_map(resource_directory: &Path, file_name: &str) -> Result<HashMap<String, Vec<String>>> {
        let mut map = HashMap::<String, Vec<String>>::new();
        for line in source_lines(resource_directory, file_name)? {
                let parts = line.split('\t').collect::<Vec<_>>();
                if parts.len() == 2 {
                        map.entry(parts[0].to_owned()).or_default().push(parts[1].to_owned());
                }
        }
        Ok(map)
}

fn definition_map(resource_directory: &Path) -> Result<HashMap<String, String>> {
        let mut definitions = HashMap::new();
        for line in source_lines(resource_directory, "definition.txt")? {
                let parts = split_fields(&line, '\t');
                if parts.len() == 3 {
                        definitions.entry(parts[0].to_owned()).or_insert_with(|| normalize_definition(parts[2]));
                }
        }
        Ok(definitions)
}

fn normalize_definition(definition: &str) -> String {
        definition.replace('\'', "’")
}

fn character_variants(resource_directory: &Path, file_name: &str) -> Result<Vec<(u32, u32)>> {
        let mut seen_lines = HashSet::new();
        let mut variants = BTreeMap::new();
        for source_line in source_lines(resource_directory, file_name)? {
                let line = source_line.trim();
                if line.is_empty() || line.starts_with('#') || !seen_lines.insert(line.to_owned()) {
                        continue;
                }
                let parts = line.split('\t').map(str::trim).collect::<Vec<_>>();
                if parts.len() < 2 || parts[0].chars().count() != 1 || parts[1].is_empty() {
                        return invalid_data(format!("bad line format in {file_name}: {line}"));
                }
                let source = u32::from(parts[0].chars().next().expect("source character was validated"));
                let single_target = parts[1].chars().count() == 1;
                let Some(target_character) = parts[1].split_whitespace().next().and_then(|text| text.chars().next()) else {
                        return invalid_data(format!("bad target character in {file_name}: {line}"));
                };
                let target = u32::from(target_character);
                if !is_generic_cjkv(source) || !is_generic_cjkv(target) {
                        eprintln!("Skipping non-CJKV character variant in {file_name}: {line}");
                        continue;
                }
                if source == target {
                        if single_target {
                                return invalid_data(format!("self-mapping character variant in {file_name}: {line}"));
                        }
                        continue;
                }
                variants.entry(source).or_insert(target);
        }
        Ok(variants.into_iter().collect())
}

fn syllable_pairs(resource_directory: &Path, file_name: &str) -> Result<Vec<(String, String)>> {
        nonempty_source_lines(resource_directory, file_name)?
                .into_iter()
                .map(|line| {
                        let parts = line.trim().split('\t').collect::<Vec<_>>();
                        if parts.len() != 2 {
                                return invalid_data(format!("bad line format in {file_name}: {line}"));
                        }
                        Ok((parts[0].to_owned(), parts[1].to_owned()))
                })
                .collect()
}

fn jyutping_words(lines: &[String], single_character_only: bool) -> Vec<String> {
        let mut words = Vec::new();
        let mut seen = HashSet::new();
        for line in lines {
                let Some(word) = line.split('\t').next() else {
                        continue;
                };
                let word = word.trim();
                if single_character_only && character_count(word) != 1 {
                        continue;
                }
                if seen.insert(word.to_owned()) {
                        words.push(word.to_owned());
                }
        }
        words
}

fn push_quick_entry(entries: &mut Vec<QuickEntry>, seen: &mut HashSet<QuickEntry>, word: &str, quick5: String, quick3: String) {
        let entry = QuickEntry {
                word: word.to_owned(),
                q5complex: character_count(&quick5),
                q5code: serial_code(&quick5),
                q3complex: character_count(&quick3),
                q3code: serial_code(&quick3),
                quick5,
                quick3,
        };
        if seen.insert(entry.clone()) {
                entries.push(entry);
        }
}

fn first_quick_code(map: &HashMap<String, Vec<String>>, character: char) -> String {
        map.get(&character.to_string()).and_then(|matches| matches.first()).map(|value| quick_code(value)).unwrap_or_else(|| "X".to_owned())
}

fn quick_code(cangjie: &str) -> String {
        let characters = cangjie.chars().collect::<Vec<_>>();
        if characters.len() > 2 { format!("{}{}", characters[0], characters[characters.len() - 1]) } else { cangjie.to_owned() }
}

fn source_lines(resource_directory: &Path, file_name: &str) -> Result<Vec<String>> {
        let path = resource_directory.join(file_name);
        let content = fs::read_to_string(&path).map_err(|error| io::Error::new(error.kind(), format!("failed to read {}: {error}", path.display())))?;
        Ok(content.trim().lines().map(|line| line.trim_end_matches('\r').to_owned()).collect())
}

fn nonempty_source_lines(resource_directory: &Path, file_name: &str) -> Result<Vec<String>> {
        Ok(source_lines(resource_directory, file_name)?.into_iter().filter(|line| !line.trim().is_empty()).collect())
}

fn exact_fields<'a>(line: &'a str, separator: char, expected_count: usize, file_name: &str) -> Result<Vec<&'a str>> {
        let parts = line.split(separator).collect::<Vec<_>>();
        if parts.len() != expected_count {
                return invalid_data(format!("bad line format in {file_name}: {line}"));
        }
        Ok(parts)
}

fn split_fields(line: &str, separator: char) -> Vec<&str> {
        line.split(separator).map(str::trim).filter(|part| !part.is_empty()).collect()
}

fn bind_texts(statement: &mut crate::database::Statement, start_index: i32, values: &[&str]) -> Result<()> {
        for (offset, value) in values.iter().enumerate() {
                statement.bind_text(start_index + i32::try_from(offset)?, value)?;
        }
        Ok(())
}

fn execute_all(database: &Database, commands: &[&str]) -> Result<()> {
        for command in commands {
                database.execute(command)?;
        }
        Ok(())
}

fn serial_code(text: &str) -> i64 {
        text.chars().filter_map(letter_code).fold(0_i64, |value, code| value.wrapping_mul(100).wrapping_add(code))
}

fn letter_code(character: char) -> Option<i64> {
        character.is_ascii_lowercase().then(|| i64::from(u32::from(character) - u32::from('a') + 20))
}

fn keypad_code(text: &str) -> i64 {
        text.chars().filter_map(keypad_digit).fold(0_i64, |value, digit| value.wrapping_mul(10).wrapping_add(digit))
}

fn keypad_digit(character: char) -> Option<i64> {
        match character {
                'a'..='c' => Some(2),
                'd'..='f' => Some(3),
                'g'..='i' => Some(4),
                'j'..='l' => Some(5),
                'm'..='o' => Some(6),
                'p'..='s' => Some(7),
                't'..='v' => Some(8),
                'w'..='z' => Some(9),
                _ => None,
        }
}

fn decimal_code(values: impl IntoIterator<Item = i64>) -> i64 {
        values.into_iter().fold(0_i64, |value, digit| value.wrapping_mul(10).wrapping_add(digit))
}

fn character_count(text: &str) -> i64 {
        i64::try_from(text.chars().count()).expect("text length exceeds i64")
}

fn first_code_point(text: &str, file_name: &str) -> Result<i64> {
        text.chars().next().map(|character| i64::from(u32::from(character))).ok_or_else(|| io::Error::new(io::ErrorKind::InvalidData, format!("empty word in {file_name}")).into())
}

fn is_generic_cjkv(code: u32) -> bool {
        matches!(
            code,
            0x4E00..=0x9FFF
                | 0x3400..=0x4DBF
                | 0x20000..=0x2A6DF
                | 0x2A700..=0x2B73F
                | 0x2B740..=0x2B81F
                | 0x2B820..=0x2CEAF
                | 0x2CEB0..=0x2EBEF
                | 0x30000..=0x3134F
                | 0x31350..=0x323AF
                | 0x2EBF0..=0x2EE5F
                | 0x323B0..=0x33479
                | 0x3007
                | 0x2E80..=0x2E99
                | 0x2E9B..=0x2EF3
                | 0x2F00..=0x2FD5
                | 0xF900..=0xFA6D
                | 0xFA70..=0xFAD9
                | 0x2F800..=0x2FA1D
        )
}

fn generate_database(output_path: &Path, populate: impl FnOnce(&Database) -> Result<()>) -> Result<()> {
        let parent = output_path.parent().ok_or("output path has no parent directory")?;
        fs::create_dir_all(parent)?;
        let temporary_path = temporary_path(output_path)?;
        if temporary_path.exists() {
                fs::remove_file(&temporary_path)?;
        }
        let temporary_file = TemporaryFile::new(temporary_path.clone());
        {
                let database = Database::open(&temporary_path)?;
                database.execute("BEGIN IMMEDIATE")?;
                populate(&database)?;
                database.execute("COMMIT")?;
        }
        replace_file(&temporary_path, output_path)?;
        temporary_file.keep();
        Ok(())
}

fn temporary_path(output_path: &Path) -> Result<PathBuf> {
        let file_name = output_path.file_name().and_then(|name| name.to_str()).ok_or("output filename is not valid UTF-8")?;
        Ok(output_path.with_file_name(format!(".{file_name}.tmp-{}", std::process::id())))
}

#[cfg(not(target_os = "windows"))]
fn replace_file(source: &Path, destination: &Path) -> Result<()> {
        fs::rename(source, destination)?;
        Ok(())
}

#[cfg(target_os = "windows")]
fn replace_file(source: &Path, destination: &Path) -> Result<()> {
        use std::os::windows::ffi::OsStrExt;

        const MOVE_FILE_REPLACE_EXISTING: u32 = 0x1;
        const MOVE_FILE_WRITE_THROUGH: u32 = 0x8;

        #[link(name = "kernel32")]
        unsafe extern "system" {
                fn MoveFileExW(existing_filename: *const u16, new_filename: *const u16, flags: u32) -> i32;
        }

        let source_wide = source.as_os_str().encode_wide().chain(Some(0)).collect::<Vec<_>>();
        let destination_wide = destination.as_os_str().encode_wide().chain(Some(0)).collect::<Vec<_>>();
        let result = unsafe { MoveFileExW(source_wide.as_ptr(), destination_wide.as_ptr(), MOVE_FILE_REPLACE_EXISTING | MOVE_FILE_WRITE_THROUGH) };
        if result == 0 {
                return Err(io::Error::last_os_error().into());
        }
        Ok(())
}

fn invalid_data<T>(message: String) -> Result<T> {
        Err(io::Error::new(io::ErrorKind::InvalidData, message).into())
}

struct TemporaryFile {
        path: PathBuf,
        keep: std::cell::Cell<bool>,
}

impl TemporaryFile {
        fn new(path: PathBuf) -> Self {
                Self { path, keep: std::cell::Cell::new(false) }
        }

        fn keep(&self) {
                self.keep.set(true);
        }
}

impl Drop for TemporaryFile {
        fn drop(&mut self) {
                if !self.keep.get() {
                        let _ = fs::remove_file(&self.path);
                }
        }
}

#[cfg(test)]
mod tests {
        use super::*;

        #[test]
        fn serial_codes_match_swift_encoding() {
                assert_eq!(serial_code("abc"), 202122);
                assert_eq!(serial_code("a-b C!"), 2021);
                assert_eq!(serial_code("activitykit"), -6749006824106374921);
        }

        #[test]
        fn keypad_codes_match_mobile_encoding() {
                assert_eq!(keypad_code("abc"), 222);
                assert_eq!(keypad_code("gwong"), 49664);
                assert_eq!(keypad_code("a-b C!"), 22);
        }

        #[test]
        fn decimal_codes_wrap_at_64_bits() {
                assert_eq!(decimal_code([2, 3, 4]), 234);
                assert_eq!(decimal_code([]), 0);
        }

        #[test]
        fn quick_codes_keep_short_codes_and_abbreviate_long_ones() {
                assert_eq!(quick_code("a"), "a");
                assert_eq!(quick_code("ab"), "ab");
                assert_eq!(quick_code("abcde"), "ae");
        }

        #[test]
        fn definitions_use_curly_apostrophes() {
                assert_eq!(normalize_definition("one's definition"), "one’s definition");
        }
}
