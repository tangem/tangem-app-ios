//
//  String+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

extension String {
    var dropTrailingPeriod: SubSequence { hasSuffix(".") ? dropLast(1) : self[...] }

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
        var modifiedString = self
        let range = NSRange(location: 0, length: modifiedString.utf16.count)
        let matches = Self.regex.matches(in: modifiedString, range: range)

        for match in matches.reversed() {
            let replacement = Self.regex.replacementString(
                for: match,
                in: modifiedString,
                offset: 0,
                template: Self.wordSeparator
            )

            guard let replacementRange = Range(match.range, in: modifiedString) else {
                continue
            }

            modifiedString.replaceSubrange(replacementRange, with: replacement)
        }

        return modifiedString
            .trimmingCharacters(in: Self.trimmingCharacterSet)
    }
}

// MARK: - Private implementation

private extension String {
    static let wordSeparator = "_"
    static let trimmingCharacterSet = CharacterSet(charactersIn: wordSeparator)
    static let regex = NSRegularExpression(replacingPattern)

    /// The `\w` meta character matches word characters.
    /// A word character is a character a-z, A-Z, 0-9, including _ (underscore).
    private static let replacingPattern = #"[^\w]+"#
}
