//
//  WalletConnectPayLinkParser.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import ReownWalletKit

struct WalletConnectPayLinkParser {
    private let isFeatureAvailable: () -> Bool

    init(isFeatureAvailable: @escaping () -> Bool = { FeatureProvider.isAvailable(.walletConnectPay) }) {
        self.isFeatureAvailable = isFeatureAvailable
    }

    func parse(_ value: String) -> WalletConnectPayLink? {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        guard
            isFeatureAvailable(),
            WalletKit.isPaymentLink(trimmedValue)
        else {
            return nil
        }

        return WalletConnectPayLink(rawValue: trimmedValue)
    }

    func parse(url: URL) -> WalletConnectPayLink? {
        parse(url.absoluteString)
    }
}

extension WalletConnectPayLinkParser: IncomingActionURLParser {
    func parse(_ url: URL) throws -> IncomingAction? {
        parse(url: url).map(IncomingAction.walletConnectPay)
    }
}
