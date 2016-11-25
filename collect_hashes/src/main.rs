extern crate crypto;
extern crate reqwest;

use std::io::{self, Read, Write};
use std::path::Path;
use std::fs;
use std::fs::File;

use crypto::md5::Md5;
use crypto::digest::Digest;

use reqwest::Client;
use reqwest::StatusCode;

#[derive(Hash, Eq, PartialEq)]
struct LoLVersion {
    region: &'static str,
    version: &'static str,
    description: &'static str
}

static VERSIONS: [LoLVersion; 8] = [
    LoLVersion {
        version: "2016_11_10",
        region: "EUW",
        description: "EU West"
    },
    LoLVersion {
        region: "NA",
        version: "2016_05_13",
        description: "North America"
    },
    LoLVersion {
        region: "EUNE",
        version: "2016_11_10",
        description: "EU Nordic & East"
    },
    LoLVersion {
        region: "OC1",
        version: "2016_05_13",
        description: "Oceania"
    },
    LoLVersion {
        region: "RU",
        version: "2016_05_13",
        description: "Russia"
    },
    LoLVersion {
        region: "LA1",
        version: "2016_05_26",
        description: "Latin America North"
    },
    LoLVersion {
        region: "LA2",
        version: "2016_05_27",
        description: "Latin America South"
    },
    LoLVersion {
        region: "BR",
        version: "2016_05_13",
        description: "Brazil"
    }
];

fn main() {
    let http_client = Client::new().expect("Couldn't create client");
    let mut regions_found = vec!();
    let mut hash = Md5::new();
    let cache_folder = Path::new("filecache");
    if !cache_folder.exists() {
        fs::create_dir(cache_folder).expect("Failed to create installer cache folder");
    }


    for version in &VERSIONS {
        let download_url = get_url(&version);
        println!("Calculating hash for url: {}", download_url);
        // Check if file exists in cache
        let executable = cache_folder.join(format!("LeagueofLegends_{}_Installer_{}.exe", version.region, version.version));
        if !executable.exists() {
            if !download(&http_client, &download_url, &executable) {
                println!("Warning: {} returned 404", download_url);
                continue;
            }
        }

        let mut file = File::open(&executable).expect(format!("Could not find installer: {:?}", executable).as_ref());


        let mut bytes = vec!();
        file.read_to_end(&mut bytes).expect("Failed to read remote content");
        hash.input(&bytes);
        let hash_result = hash.result_str();
        println!("{}", &hash_result);
        regions_found.push((version, hash_result));
        hash.reset();
    }

    let hashes_map: Vec<String> = regions_found.iter()
        .map(|&(ref version, ref hash)| format!("[\"{}\"]=\"{}\"", version.description, hash))
        .collect();
    let url_map: Vec<String> = regions_found.iter()
        .map(|&(ref version, _)| format!("[\"{}\"]=\"{}\"", version.description, get_url(&version)))
        .collect();
    let region_map: Vec<String> = regions_found.iter()
        .map(|&(ref version, _)| format!("[\"{}\"]=\"{}\"", version.description, version.region))
        .collect();
    let description_map: Vec<String> = regions_found.iter()
        .map(|&(ref version, _)| version.description.to_owned())
        .collect();
    println!("declare -A HASHES=( {} )", hashes_map.join(" "));
    println!("declare -A URLS=( {} )", url_map.join(" "));
    println!("declare -A REGIONS=( {} )", region_map.join(" "));
    println!("REGION_DESC=\"{}\"", description_map.join("|"));
}

fn download(http_client: &Client, download_url: &String, path: &Path) -> bool {
    let mut result = http_client.get(download_url).send().expect("Failed to download file");
    if *(result.status()) != StatusCode::Ok {
        return false;
    }
    let mut out_file = File::create(path).expect("Could not create file.");
    io::copy(&mut result, &mut out_file).expect("Failed to write to file.");
    true
}

fn get_url(version: &LoLVersion) -> String {
    format!("https://riotgamespatcher-a.akamaihd.net/ShellInstaller/{region}/LeagueofLegends_{region}_Installer_{version}.exe",
            region = version.region, version = version.version)
}
