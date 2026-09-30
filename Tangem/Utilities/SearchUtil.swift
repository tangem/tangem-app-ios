//
//  SearchUtil.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemFoundation

enum SearchUtil<T> {
    /// Filters `items` whose `keyPath` value contains `searchText` (case-insensitive).
    /// Items with a word starting with `searchText` come first; the relative order of `items` is preserved within each group.
    static func search(_ items: [T], in keyPath: KeyPath<T, String>, for searchText: String) -> [T] {
        if searchText.isEmpty {
            return items
        }

        let searchText = searchText.trimmed()

        var wordPrefixMatches: [T] = []
        var otherMatches: [T] = []

        for item in items {
            let value = item[keyPath: keyPath]

            guard value.caseInsensitiveContains(searchText) else {
                continue
            }

            let hasWordPrefixMatch = value
                .split(separator: " ")
                .contains { $0.caseInsensitiveHasPrefix(searchText) }

            if hasWordPrefixMatch {
                wordPrefixMatches.append(item)
            } else {
                otherMatches.append(item)
            }
        }

        return wordPrefixMatches + otherMatches
    }
}
