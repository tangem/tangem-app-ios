//
//  TangemPayBankRecipient.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct TangemPayBankRecipient {
    let fullName: String
    let shortName: String
    let monogram: String
    let accountNumber: String
    let isBusiness: Bool

    static let john = TangemPayBankRecipient(
        fullName: "John Doe",
        shortName: "John D.",
        monogram: "J",
        accountNumber: "123456789012",
        isBusiness: false
    )

    static let acme = TangemPayBankRecipient(
        fullName: "Acme Corp",
        shortName: "Acme Corp",
        monogram: "A",
        accountNumber: "987654321098",
        isBusiness: true
    )

    static let alice = TangemPayBankRecipient(
        fullName: "Alice Smith",
        shortName: "Alice S.",
        monogram: "A",
        accountNumber: "555500001111",
        isBusiness: false
    )

    static let bob = TangemPayBankRecipient(
        fullName: "Bob Brown",
        shortName: "Bob B.",
        monogram: "B",
        accountNumber: "444400002222",
        isBusiness: false
    )

    static let carol = TangemPayBankRecipient(
        fullName: "Carol White",
        shortName: "Carol W.",
        monogram: "C",
        accountNumber: "333300003333",
        isBusiness: false
    )

    static let jane = TangemPayBankRecipient(
        fullName: "Jane Roe",
        shortName: "Jane R.",
        monogram: "J",
        accountNumber: "246813579024",
        isBusiness: false
    )

    func isMonogramLeading(in label: String) -> Bool {
        guard label.hasPrefix(monogram) else { return false }
        return label.dropFirst(monogram.count).first.map { !$0.isLetter } ?? false
    }

    static let fiveSavedAccounts: [TangemPayBankRecipient] = [.john, .acme, .alice, .bob, .carol]
}
