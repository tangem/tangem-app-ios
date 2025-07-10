//
//  UTXOPreImageTransactionBuilder+.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

// MARK: - BranchAndBoundPreImageTransactionBuilder

extension UTXOPreImageTransactionBuilder where Self == BranchAndBoundPreImageTransactionBuilder {
    static func bitcoin(isTestnet: Bool) -> Self {
        BranchAndBoundPreImageTransactionBuilder(
            calculator: CommonUTXOTransactionSizeCalculator(network: isTestnet ? BitcoinTestnetNetworkParams() : BitcoinNetworkParams())
        )
    }

    static func litecoin() -> Self {
        BranchAndBoundPreImageTransactionBuilder(
            calculator: CommonUTXOTransactionSizeCalculator(network: LitecoinNetworkParams())
        )
    }

    static func bitcoinCash(isTestnet: Bool) -> Self {
        BranchAndBoundPreImageTransactionBuilder(
            calculator: CommonUTXOTransactionSizeCalculator(network: isTestnet ? BitcoinCashTestNetworkParams() : BitcoinCashNetworkParams())
        )
    }

    static func dogecoin() -> Self {
        BranchAndBoundPreImageTransactionBuilder(
            calculator: CommonUTXOTransactionSizeCalculator(network: DogecoinNetworkParams())
        )
    }

    static func dash(isTestnet: Bool) -> Self {
        BranchAndBoundPreImageTransactionBuilder(
            calculator: CommonUTXOTransactionSizeCalculator(network: isTestnet ? DashTestNetworkParams() : DashMainNetworkParams())
        )
    }

    static func ravencoin(isTestnet: Bool) -> Self {
        BranchAndBoundPreImageTransactionBuilder(
            calculator: CommonUTXOTransactionSizeCalculator(network: isTestnet ? RavencoinTestNetworkParams() : RavencoinMainNetworkParams())
        )
    }

    static func ducatus() -> Self {
        BranchAndBoundPreImageTransactionBuilder(
            calculator: CommonUTXOTransactionSizeCalculator(network: DucatusNetworkParams())
        )
    }

    static func clore() -> Self {
        BranchAndBoundPreImageTransactionBuilder(
            calculator: CommonUTXOTransactionSizeCalculator(network: CloreMainNetworkParams())
        )
    }

    static func radiant() -> Self {
        BranchAndBoundPreImageTransactionBuilder(
            calculator: CommonUTXOTransactionSizeCalculator(network: CloreMainNetworkParams())
        )
    }

    static func kaspa() -> Self {
        BranchAndBoundPreImageTransactionBuilder(
            calculator: KaspaUTXOTransactionSizeCalculator(network: KaspaNetworkParams())
        )
    }

    static func fact0rn() -> Self {
        BranchAndBoundPreImageTransactionBuilder(
            calculator: CommonUTXOTransactionSizeCalculator(network: Fact0rnMainNetworkParams())
        )
    }

    static func pepecoin(isTestnet: Bool) -> Self {
        BranchAndBoundPreImageTransactionBuilder(
            calculator: CommonUTXOTransactionSizeCalculator(network: isTestnet ? PepecoinTestnetNetworkParams() : PepecoinMainnetNetworkParams())
        )
    }
}
