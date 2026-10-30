//
//  MarketingActivityUid.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

enum MarketingActivityUid {
    private static let queryKey = "uid"

    static func read(from url: URL) -> String? {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first { $0.name == queryKey && $0.value?.isEmpty == false }?
            .value
    }

    static func loggableLink(_ url: URL) -> String {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.percentEncodedQueryItems,
              queryItems.contains(where: isUid) else {
            return url.absoluteString
        }

        components.percentEncodedQueryItems = queryItems.map { item in
            guard isUid(item), let value = item.value, !value.isEmpty else {
                return item
            }

            let masked = (value.removingPercentEncoding ?? value).masked()
            return URLQueryItem(name: item.name, value: masked.addingPercentEncoding(withAllowedCharacters: maskedValueAllowed) ?? "***")
        }

        return components.string ?? url.absoluteString
    }

    static func loggableLink(_ link: String) -> String {
        URL(string: link).map(loggableLink) ?? link
    }

    static func linkWithoutUid(_ link: String) -> String {
        guard var components = URLComponents(string: link),
              let queryItems = components.percentEncodedQueryItems,
              queryItems.contains(where: isUid) else {
            return link
        }

        let remainingItems = queryItems.filter { !isUid($0) }
        components.percentEncodedQueryItems = remainingItems.isEmpty ? nil : remainingItems

        return components.string ?? link
    }
}

// MARK: - Private

private extension MarketingActivityUid {
    static let maskedValueAllowed = CharacterSet.urlQueryAllowed.subtracting(CharacterSet(charactersIn: "&=+#"))

    static func isUid(_ item: URLQueryItem) -> Bool {
        item.name.removingPercentEncoding == queryKey
    }
}
