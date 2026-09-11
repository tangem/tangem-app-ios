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

    init?(_ mask: String) {
        guard let slotIndex = mask.firstIndex(of: Constants.digitSlot) else {
            return nil
        }

        prefix = String(mask[..<slotIndex])
        template = String(mask[slotIndex...])
    }

    func apply(to text: String) -> String {
        // Deleting into the prefix pins it back — the country code is part of the format, not of the input.
        guard !prefix.hasPrefix(text) else {
            return prefix
        }

        return prefix + filled(with: digits(of: text))
    }

    /// Sample digits run through the mask, so an empty field hints at the shape with a plausible number
    /// rather than a row of slots.
    var placeholder: String {
        let slots = template.filter { $0 == Constants.digitSlot }.count
        let repeats = slots / Constants.sampleDigits.count + 1
        let sample = String(repeating: Constants.sampleDigits, count: repeats)

        return prefix + filled(with: String(sample.prefix(slots)))
    }

    func digitCount(in text: String) -> Int {
        digits(of: text).count
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
        static let sampleDigits = "8005553535"
    }

    func digits(of text: String) -> String {
        let body = text.hasPrefix(prefix) ? String(text.dropFirst(prefix.count)) : text
        let digits = body.filter(\.isWholeNumber)
        let prefixDigits = prefix.filter(\.isWholeNumber)

        // A number carrying its own country code — typed, or pasted from Contacts as `+1 (800) 555-3535` —
        // repeats the digits the prefix already shows. Dropping them is what keeps the two from stacking up.
        guard !prefixDigits.isEmpty, digits.hasPrefix(prefixDigits) else {
            return digits
        }

        return String(digits.dropFirst(prefixDigits.count))
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
