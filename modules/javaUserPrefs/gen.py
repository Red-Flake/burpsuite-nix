#!/usr/bin/env python3
import argparse
import base64
import pathlib

# https://hg.openjdk.org/jdk8/jdk8/jdk/file/687fd7c7986d/src/share/classes/java/util/prefs/Base64.java#l100
# https://hg.openjdk.org/jdk8/jdk8/jdk/file/687fd7c7986d/src/share/classes/java/util/prefs/Base64.java#l115
table = str.maketrans(
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ/",
    "!\"#$%&'(),-.:;<>@[]^`_{|}~?",
)


# https://hg.openjdk.org/jdk8/jdk8/jdk/file/687fd7c7986d/src/solaris/classes/java/util/prefs/FileSystemPreferences.java#l837
def isDirChar(c) -> bool:
    return c > chr(0x1F) and c < chr(0x7F) and c not in "/._"


# https://hg.openjdk.org/jdk8/jdk8/jdk/file/687fd7c7986d/src/solaris/classes/java/util/prefs/FileSystemPreferences.java#l847
def dirName(name: str) -> str:
    if all(isDirChar(c) for c in name):
        return name
    return "_" + base64.b64encode(byteArray(name)).decode().translate(table)


# https://hg.openjdk.org/jdk8/jdk8/jdk/file/687fd7c7986d/src/solaris/classes/java/util/prefs/FileSystemPreferences.java#l858
def byteArray(s: str) -> bytes:
    result = bytearray()
    for c in s:
        o = ord(c)
        result.append((o >> (8 * 1) & 0xFF))
        result.append((o >> (8 * 0) & 0xFF))
    return bytes(result)

# --- NEW: parse CLI argument ---
parser = argparse.ArgumentParser(description="Encode a directory path for Java prefs")
parser.add_argument("--directory", type=str, required=True, help="Directory to encode")
args = parser.parse_args()

input_path = pathlib.Path(args.directory)
encoded_parts = [dirName(part) for part in input_path.parts]
encoded_path = pathlib.Path(*encoded_parts)

print(encoded_path)