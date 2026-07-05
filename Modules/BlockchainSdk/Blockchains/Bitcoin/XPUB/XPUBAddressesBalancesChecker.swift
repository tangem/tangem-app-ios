//
//  XPUBAddressesBalancesChecker.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public protocol XPUBAddressesBalancesChecker {
    func checkOtherAddressesBalances(xpubKey: Wallet.PublicKey.XPUBKey) async throws -> XPUBAddressesBalancesReport
}

public struct XPUBAddressesBalancesReport {
    public let otherAddressesBalances: [String: Decimal]

    public var hasBalances: Bool {
        otherAddressesBalances.contains(where: { $0.value > 0 })
    }

    public init(otherAddressesBalances: [String: Decimal]) {
        self.otherAddressesBalances = otherAddressesBalances
    }
}
