//
//  String+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Regex

extension String {
    var dropTrailingPeriod: SubSequence { hasSuffix(".") ? dropLast(1) : self[...] }

    var hexToInteger: Int? { Int(removeHexPrefix(), radix: 16) }

    var integerToHex: String { .init(Int(self) ?? 0, radix: 16) }

    func removeLatestSlash() -> String {
        if last == "/" {
            return String(dropLast())
        }

        return self
    }

    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }

    mutating func capitalizeFirstLetter() {
        self = capitalizingFirstLetter()
    }

    func remove(contentsOf strings: [String]) -> String {
        strings.reduce(into: self) {
            $0 = $0.remove($1)
        }
    }

    func trimmed() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func camelCaseToSnakeCase() -> String {
        let regex = try! NSRegularExpression(pattern: "([A-Z])", options: [])
        let range = NSRange(location: 0, length: count)
        return regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "_$1").lowercased()
    }

    /// Converts string to underscored format (words separated by `_`).
    ///
    /// Non-word characters (anything other than letters, numbers, and underscore)
    /// are replaced with underscores. Leading and trailing underscores are trimmed.
    func toUnderscoreCase() -> String {
        let replacingPattern: StaticString = "[^\\w]+"
        let wordSeparator = "_"
        let trimmingCharacterSet = CharacterSet(charactersIn: wordSeparator)
        return replacingAll(matching: replacingPattern, with: wordSeparator).trimmingCharacters(in: trimmingCharacterSet)
    }
}
