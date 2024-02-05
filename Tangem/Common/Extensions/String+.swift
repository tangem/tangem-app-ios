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
}

extension String {
    subscript(value: Int) -> Character {
        self[index(at: value)]
    }

    subscript(value: NSRange) -> Substring {
        self[value.lowerBound ..< value.upperBound]
    }

    subscript(value: CountableClosedRange<Int>) -> Substring {
        self[index(at: value.lowerBound) ... index(at: value.upperBound)]
    }

    subscript(value: CountableRange<Int>) -> Substring {
        self[index(at: value.lowerBound) ..< index(at: value.upperBound)]
    }

    subscript(value: PartialRangeUpTo<Int>) -> Substring {
        self[..<index(at: value.upperBound)]
    }

    subscript(value: PartialRangeThrough<Int>) -> Substring {
        self[...index(at: value.upperBound)]
    }

    subscript(value: PartialRangeFrom<Int>) -> Substring {
        self[index(at: value.lowerBound)...]
    }

    private func index(at offset: Int) -> String.Index {
        index(startIndex, offsetBy: offset)
    }
}
