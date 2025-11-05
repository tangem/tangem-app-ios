//
//  UnarchivedCryptoAccountNameIndexer.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum UnarchivedCryptoAccountNameIndexer {
    static func makeAccountName(from string: String) -> String {
        let (newIndex, currentIndex) = extractIndices(from: string)
        let accountNameSuffix = makeString(fromIndex: newIndex)
        let accountNamePrefixLength = max(AccountModelUtils.maxAccountNameLength - accountNameSuffix.count, 0)

        var accountNamePrefix = string
        if let currentIndex {
            let accountNameCurrentSuffix = makeString(fromIndex: currentIndex)
            let accountNameCurrentSuffixLength = accountNameCurrentSuffix.count
            accountNamePrefix = String(accountNamePrefix.dropLast(accountNameCurrentSuffixLength))
        }

        accountNamePrefix = String(accountNamePrefix.prefix(accountNamePrefixLength))

        return accountNamePrefix + accountNameSuffix
    }

    private static func extractIndices(from string: String) -> (newIndex: Int, currentIndex: Int?) {
        let pattern = #"\\#(Constants.indexPrefix)(\d+)\\#(Constants.indexSuffix)$"#
        let regex = try! NSRegularExpression(pattern: pattern)
        let fullRange = NSRange(location: 0, length: string.utf16.count)

        guard
            let match = regex.firstMatch(in: string, range: fullRange),
            let matchRange = Range(match.range, in: string)
        else {
            return (Constants.initialIndex, nil)
        }

        let currentIndexString = string[matchRange].dropFirst().dropLast()

        guard let currentIndex = Int(currentIndexString) else {
            return (Constants.initialIndex, nil)
        }

        return (currentIndex + 1, currentIndex)
    }

    private static func makeString(fromIndex index: Int) -> String {
        return "\(Constants.indexPrefix)\(index)\(Constants.indexSuffix)"
    }
}

// MARK: - Constant

private extension UnarchivedCryptoAccountNameIndexer {
    enum Constants {
        static let initialIndex = 1
        static let indexPrefix = "("
        static let indexSuffix = ")"
    }
}
