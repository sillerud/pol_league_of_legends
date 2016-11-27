extern crate crypto;
extern crate reqwest;

use std::fs::{self, File};
use std::io::prelude::*;
use std::path::Path;

use crypto::md5::Md5;
use crypto::digest::Digest;

use reqwest::{Client, StatusCode};

#[derive(Debug)]
struct LoLVersion {
    region: &'static str,
    version: &'static str,
    desc: &'static str,
}

static VERSIONS: &'static [LoLVersion] = &[
    LoLVersion { region: "EUW", version: "2016_11_10", desc: "EU West" },
    LoLVersion { region: "NA", version: "2016_05_13", desc: "North America" },
    LoLVersion { region: "EUNE", version: "2016_11_10", desc: "EU Nordic & East" },
    LoLVersion { region: "OC1", version: "2016_05_13", desc: "Oceania" },
    LoLVersion { region: "RU", version: "2016_05_13", desc: "Russia" },
    LoLVersion { region: "LA1", version: "2016_05_26", desc: "Latin America North" },
    LoLVersion { region: "LA2", version: "2016_05_27", desc: "Latin America South" },
    LoLVersion { region: "BR", version: "2016_05_13", desc: "Brazil" },
];

fn main() {
    let cache_path = Path::new("filecache");

    if !cache_path.exists() {
        fs::create_dir(cache_path).expect("Could not create cache directory");
    }

    let client = Client::new().expect("Could not create http client");
    let mut hash = Md5::new();
    
    let (mut hashes, mut urls, mut regions, mut desc) = VERSIONS.iter()
        .filter_map(|v| {
            let url = format!("https://riotgamespatcher-a.akamaihd.net/ShellInstaller/{region}/LeagueofLegends_{region}_Installer_{version}.exe",
                region = v.region, version = v.version);

            println!("Calculating hash for: {}", v.desc);

            let exec = cache_path.join(format!("LeagueofLegends_{}_Installer_{}.exe", v.region, v.version));
            let mut buf = vec![];

            if exec.exists() {
                // If the installer already exists then we just read from it.
                if File::open(&exec).and_then(|mut f| f.read_to_end(&mut buf)).is_err() {
                    println!("Warning: Could not read from installer: {:?}", exec);
                    return None;
                }
            } else {
                // If not we attempt to download and cache the installer.
                if match client.get(&url).send() {
                    Ok(ref mut r) if *r.status() == StatusCode::Ok => {
                        r.read_to_end(&mut buf)
                            .and_then(|_| File::create(&exec))
                            .and_then(|mut f| f.write_all(&buf))
                            .ok()
                    }
                    _ => Some(()),
                }.is_none() {
                    println!("Warning: Could not download or save installer: {:?}", exec);
                    return None;
                }
            }

            hash.input(&buf);
            let hash_str = hash.result_str();
            println!("{}", &hash_str);
            hash.reset();

            Some((hash_str, url, v))
        })
        .fold((String::new(), String::new(), String::new(), String::new()), |s, (ref hash, ref url, v)| {
            ((s.0 + "[\"" + v.desc + "\"]=\"" + hash + "\" "),
             (s.1 + "[\"" + v.desc + "\"]=\"" + url + "\" "),
             (s.2 + "[\"" + v.desc + "\"]=\"" + v.region + "\" "),
             (s.3 + v.desc + "|"))
        });

    // For now we just pop the extra last character off of each string because of the fold.
    hashes.pop(); urls.pop(); regions.pop(); desc.pop();

    println!("declare -A HASHES=( {} )", hashes);
    println!("declare -A URLS=( {} )", urls);
    println!("declare -A REGIONS=( {} )", regions);
    println!("REGION_DESC=\"{}\"", desc);
}