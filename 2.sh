#!/bin/bash

git filter-repo --replace-refs delete-no-add --force \
--file-info-callback '
import sys

sys.path.append("Utilities/public-repo-sync-support")
from clear_sensitive_data_patterns import redact_file_content, should_ignore_file

if should_ignore_file(filename):
    return (filename, mode, blob_id)

file_content = value.get_contents_by_identifier(blob_id).decode("utf-8", errors="ignore")
redacted_file_content = redact_file_content(file_content)

try:
    encoded_file_content = redacted_file_content.encode("utf-8")
    new_blob_id = value.insert_file_with_contents(encoded_file_content)
except Exception as e:
    print(f"Error encoding or inserting file '{filename}': {e}")
    raise

return (filename, mode, new_blob_id)
'