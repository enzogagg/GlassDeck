use std::fs;
use std::path::{Path, PathBuf};

pub fn first_dir<P, F>(base: P, predicate: F) -> Option<PathBuf>
where
    P: AsRef<Path>,
    F: Fn(&Path) -> bool,
{
    fs::read_dir(base)
        .ok()?
        .filter_map(Result::ok)
        .map(|entry| entry.path())
        .find(|path| path.is_dir() && predicate(path))
}

pub fn read_trimmed<P: AsRef<Path>>(path: P) -> Option<String> {
    fs::read_to_string(path)
        .ok()
        .map(|value| value.trim().to_string())
        .filter(|value| !value.is_empty())
}
