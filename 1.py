#!/usr/bin/env python3

import os
import sys

sys.path.append("Utilities/public-repo-sync-support")
from clear_sensitive_data_patterns import redact_file_content, should_ignore_file


def find_files(directory="."):
    found_files = []

    # Walk through directory tree
    for root, dirs, files in os.walk(directory):
        for file in files:
            if not should_ignore_file(file.encode()):
                found_files.append(os.path.join(root, file))

    return found_files


def main():
    found_files = find_files()

    print(f"Found {len(found_files)} files to process:")

    for found_file in found_files:
        try:
            # Read file content
            with open(found_file, "r", encoding="utf-8") as f:
                original_content = f.read()

            # Apply regex patterns
            modified_content = redact_file_content(original_content)

            # Check if content changed
            if original_content != modified_content:
                print(f"Modified: {found_file}")

                # Write back to file
                with open(found_file, "w", encoding="utf-8") as f:
                    f.write(modified_content)

        except Exception as e:
            print(f"Error processing {found_file}: {e}")
            raise e


if __name__ == "__main__":
    main()
