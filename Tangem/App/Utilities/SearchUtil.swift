//
//  SearchUtil.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

enum SearchUtil<T> {
    static func search(_ items: [T], in keyPath: KeyPath<T, String>, for searchText: String) -> [T] {
        if searchText.isEmpty {
            return items
        }

        let loweccasedSearchText = searchText.lowercased()

        return items
            .filter { item in
                item[keyPath: keyPath]
                    .lowercased()
                    .contains(loweccasedSearchText)
            }
            .sorted { item, _ in
                item[keyPath: keyPath]
                    .split(separator: " ")
                    .contains { $0.starts(with: searchText) }
            }
    }
}
