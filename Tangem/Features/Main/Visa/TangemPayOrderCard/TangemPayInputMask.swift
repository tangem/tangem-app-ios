//
//  TangemPayInputMask.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct TangemPayInputMask {
    /// Everything ahead of the first slot, held apart so the template it leaves behind carries no digits of
    /// its own.
    let prefix: String

    private let template: String

    /// Rejects a mask without the country code that E.164 is built from, so the caller falls back to digits.
    init?(_ mask: String) {
        guard mask.hasPrefix("+"), let slotIndex = mask.firstIndex(of: Constants.digitSlot) else {
            return nil
        }

        let prefix = String(mask[..<slotIndex])

        guard prefix.contains(where: \.isWholeNumber) else {
            return nil
        }

        self.prefix = prefix
        template = String(mask[slotIndex...])
    }

    func apply(to text: String) -> String {
        // Deleting into the prefix pins it back — the country code is part of the format, not of the input.
        guard !prefix.hasPrefix(text) else {
            return prefix
        }

        return prefix + filled(with: digits(of: text))
    }

    var placeholder: String {
        prefix + filled(with: String(repeating: Constants.emptySlot, count: slotCount))
    }

    func digitCount(in text: String) -> Int {
        digits(of: text).count
    }

    var slotCount: Int {
        template.count { $0 == Constants.digitSlot }
    }

    func e164(from text: String) -> String {
        "+" + apply(to: text).filter(\.isWholeNumber)
    }

    /// Where the caret belongs once `count` digits precede it. It has to be tracked by digits rather than by
    /// raw offset, because inserting a separator shifts every offset behind it.
    func offset(afterDigits count: Int, in text: String) -> Int {
        var remaining = count
        var offset = prefix.count
        var templateIndex = template.startIndex

        while templateIndex < template.endIndex, remaining > 0 {
            if template[templateIndex] == Constants.digitSlot {
                remaining -= 1
            }

            template.formIndex(after: &templateIndex)
            offset += 1
        }

        return min(offset, text.count)
    }
}

private extension TangemPayInputMask {
    enum Constants {
        static let digitSlot: Character = "#"
        static let emptySlot: Character = "_"
    }

    func digits(of text: String) -> String {
        let entered = text.hasPrefix(prefix) ? String(text.dropFirst(prefix.count)) : text
        let digits = entered.filter(\.isWholeNumber)
        let countryCode = prefix.filter(\.isWholeNumber)

        guard digits.count > slotCount, digits.hasPrefix(countryCode) else {
            return digits
        }

        return String(digits.dropFirst(countryCode.count))
    }

    func filled(with digits: String) -> String {
        var result = ""
        var digitIndex = digits.startIndex

        for character in template {
            guard digitIndex < digits.endIndex else { break }

            if character == Constants.digitSlot {
                result.append(digits[digitIndex])
                digits.formIndex(after: &digitIndex)
            } else {
                result.append(character)
            }
        }

        return result
    }
}
