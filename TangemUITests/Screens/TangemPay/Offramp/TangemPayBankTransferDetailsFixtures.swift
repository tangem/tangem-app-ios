//
//  TangemPayBankTransferDetailsFixtures.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension TangemPayBankTransferWizardScreen.RecipientDetails {
    static let jane = Self(
        accountNumber: TangemPayBankRecipient.jane.accountNumber,
        routingNumber: "021000021",
        name: .individual(firstName: "Jane", lastName: "Roe"),
        country: "United States",
        region: "California",
        city: "Los Angeles",
        addressLine1: "1 Main Street",
        postalCode: "90001"
    )

    static let michael = Self(
        accountNumber: "9876543210",
        routingNumber: "026009593",
        name: .individual(firstName: "Michael", lastName: "Scott"),
        country: "United States",
        region: "California",
        city: "Los Angeles",
        addressLine1: "1 Main Street",
        postalCode: "32501"
    )

    static let emily = Self(
        accountNumber: "8765432109",
        routingNumber: "021000021",
        name: .individual(firstName: "Emily", lastName: "Clark"),
        country: "United States",
        region: "California",
        city: "Los Angeles",
        addressLine1: "1 Main Street",
        postalCode: "32501"
    )

    static let dunderMifflin = Self(
        accountNumber: "7654321098",
        routingNumber: "121000248",
        name: .business("Dunder Mifflin"),
        country: "United States",
        region: "California",
        city: "Los Angeles",
        addressLine1: "1 Main Street",
        postalCode: "32501"
    )
}

extension TangemPayBankTransferWizardScreen.BankDetails {
    static let chase = newYorkBank(named: "Chase Bank")
    static let bankOfAmerica = newYorkBank(named: "Bank of America")
    static let jpMorganChase = newYorkBank(named: "JPMorgan Chase")
    static let wellsFargo = newYorkBank(named: "Wells Fargo Bank")

    private static func newYorkBank(named name: String) -> Self {
        Self(
            name: name,
            region: "New York",
            city: "New York",
            addressLine1: "270 Park Avenue",
            postalCode: "10017"
        )
    }
}
