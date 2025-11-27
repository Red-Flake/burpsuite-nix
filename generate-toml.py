#!/usr/bin/env nix-shell
#!nix-shell -p "python3.withPackages (p: with p; [ tomli tomli-w packaging requests])" -i python3

import base64
import subprocess
import requests
import tomli_w
import hashlib
import os
import argparse
from urllib.parse import urlparse
from collections import OrderedDict


BAPP_URL = "https://portswigger.net/bappstore/currentlist"

def file_hash(data: str) -> str:
    return hashlib.sha256(data.encode("utf-8")).hexdigest()


def prefetch_hash(url: str) -> str:
    """Use nix to prefetch the file and return the sha256 hash."""
    cmd = [
        "nix", "store", "prefetch-file",
        "--hash-type", "sha256",
        "--refresh",
        "--unpack",
        "--extra-experimental-features", "nix-command",
        url
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(f"Prefetch failed for {url}: {result.stderr}")

    import re
    match = re.search(r"hash\s+'(sha256-.{44})'", result.stderr)
    if not match:
        raise RuntimeError(f"Cannot extract hash from: {result.stderr}")

    return match.group(1)


def parse_extension_block(block: str) -> dict:
    """Parse metadata block into a dictionary."""
    data = {}
    for line in block.strip().splitlines():
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        data[key.strip()] = value.strip()
    return data


def extract_shortname(meta: dict) -> str:
    """Get the TOML key prefix from RepoUrl last path component."""
    repo = meta.get("RepoUrl")
    if repo:
        try:
            parsed = urlparse(repo)
            part = parsed.path.strip("/").split("/")[-1]
            if part:
                return part.lower()
        except Exception:
            pass

    # fallback if RepoUrl missing or invalid
    name = meta.get("Name", "").lower()
    return name.replace(" ", "-")


def generate_burp_metadata(output_file: str, currentlist_path: str) :
    print("Fetching extension list...")
    raw = requests.get(BAPP_URL, timeout=15)
    raw.raise_for_status()

    new_list_raw = raw.text

    if os.path.exists(currentlist_path):
        with open(currentlist_path, "r", encoding="utf-8") as f:
            old_list_raw = f.read()

        if file_hash(new_list_raw) == file_hash(old_list_raw):
            print("No changes detected in currentlist. Nothing to update.")
            return
    else:
        os.makedirs(os.path.dirname(currentlist_path), exist_ok=True)

    # Save new version
    with open(currentlist_path, "w", encoding="utf-8") as f:
        f.write(new_list_raw)

    print("Changes detected. Regenerating metadata...")

    lines = raw.text.splitlines()
    encoded_lines = lines[2:-1]

    extensions = OrderedDict()

    print(f"Found {len(encoded_lines)} encoded extensions. Decoding...")

    for idx, enc in enumerate(encoded_lines, 1):
        try:
            decoded = base64.b64decode(enc).decode("utf-8")
        except Exception as e:
            print(f"Failed to decode line {idx}: {e}")
            continue

        meta = parse_extension_block(decoded)

        uuid = meta.get("Uuid")
        name = meta.get("Name")
        download_url = meta.get("DownloadUrl")
        screen_version = meta.get("ScreenVersion")
        serial_version = meta.get("SerialVersion")
        extensiontype = meta.get("ExtensionType")

        if not (uuid and name and download_url and screen_version):
            print(f"Skipping incomplete entry: {meta}")
            continue

        # derive the TOML table key prefix from RepoUrl
        shortname = extract_shortname(meta)

        print(f"[{idx}/{len(encoded_lines)}] Prefetching: {shortname} ({uuid})")

        try:
            sha256 = prefetch_hash(download_url)
        except Exception as e:
            print(f"Prefetch failed, skipping extension {uuid}: {e}")
            continue

        if shortname not in extensions:
            extensions[shortname] = OrderedDict()

        extensions[shortname][screen_version] = OrderedDict(
            name=name,
            uuid=uuid,
            hash=sha256,
            serialversion=str(serial_version),
            extensiontype=str(extensiontype),
        )

    print("Writing to", output_file)
    with open(output_file, "wb") as f:
        tomli_w.dump(extensions, f)

    print("Done.")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-o", "--output",
        default="burp-extensions.toml",
        help="Output TOML file"
    )
    parser.add_argument(
        "--currentlist",
        default="data/currentlist",
        help="Path to the stored currentlist file",
    )
    args = parser.parse_args()
    generate_burp_metadata(args.output, args.currentlist)


if __name__ == "__main__":
    main()
