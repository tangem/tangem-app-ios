//
//  CardIdFormatter.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct TapCardIdFormatter {
    let cid: String

    func formatted() -> String {
        var resultString = ""
        for (index, character) in cid.enumerated() {
            resultString.append(character)
            if index ==  3 || index == 7 || index == 11 {
                resultString.append(" ")
            }
        }
        return resultString
    }
}

struct TapTwinCardIdFormatter {
    static func format(cid: String, cardNumber: Int?) -> String {
        String(cid.dropLast().suffix(4)) + (cardNumber != nil ? " #\(cardNumber!)" : "")
    }
}
