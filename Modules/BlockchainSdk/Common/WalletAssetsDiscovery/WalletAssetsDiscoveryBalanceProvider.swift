//
//  WalletAssetsDiscoveryBalanceProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public protocol WalletAssetsDiscoveryBalanceProvider {
    func canHandle(_ blockchain: Blockchain) -> Bool

    func configuration(
        for blockchain: Blockchain,
        address: String
    ) async throws -> WalletAssetsDiscoveryBalanceConfiguration
}

public struct WalletAssetsDiscoveryBalanceConfiguration: Sendable {
    public let nativeBalance: Decimal
    public let tokens: [WalletAssetsDiscoveryTokenBalance]

    public var hasNativeBalance: Bool {
        nativeBalance > 0
    }

    public init(nativeBalance: Decimal, tokens: [WalletAssetsDiscoveryTokenBalance]) {
        self.nativeBalance = nativeBalance
        self.tokens = tokens
    }
}

public struct WalletAssetsDiscoveryTokenBalance: Sendable, Hashable {
    public let contractAddress: String
    public let balance: Decimal

    public init(contractAddress: String, balance: Decimal) {
        self.contractAddress = contractAddress
        self.balance = balance
    }
}
