//
//  AddressesInfoScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import UIKit
import TangemAccessibilityIdentifiers

final class AddressesInfoScreen: ScreenBase<AddressesInfoScreenElement> {
    private lazy var addressesInfoText = staticText(.addressesInfoText)

    @discardableResult
    func copyJSON() -> String {
        XCTContext.runActivity(named: "Copy JSON to clipboard") { _ in
            waitAndAssertTrue(addressesInfoText, "Addresses text info field should exist")
            return addressesInfoText.label
        }
    }

    @discardableResult
    func verifyDerivationPath(forNetwork network: String, expected: String) -> Self {
        XCTContext.runActivity(named: "Verify derivation path '\(expected)' for network \(network)") { _ in
            let json = copyJSON()
            let wallets: [WalletInfoJSON]
            do {
                wallets = try JSONDecoder().decode([WalletInfoJSON].self, from: Data(json.utf8))
            } catch {
                XCTFail("Failed to parse Addresses Info JSON: \(error)")
                return self
            }

            guard let wallet = wallets.first(where: { $0.blockchain == network }) else {
                XCTFail("No wallet found for network \(network) in Addresses Info")
                return self
            }

            XCTAssertEqual(
                wallet.derivationPath,
                expected,
                "Derivation path for \(network) should be '\(expected)'"
            )
            return self
        }
    }
}

enum AddressesInfoScreenElement: String, UIElement {
    case addressesInfoText

    var accessibilityIdentifier: String {
        switch self {
        case .addressesInfoText:
            return CommonUIAccessibilityIdentifiers.addressesInfoText
        }
    }
}
