//
//  SendTransactionValidatorFactoryTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import Testing
@testable import BlockchainSdk
@testable import Tangem

@Suite("SendTransactionValidatorFactory")
struct SendTransactionValidatorFactoryTests {
    @Test("A chain whose swap is signed from a provider-built PSBT gets the PSBT validator", arguments: PsbtBlockchain.allCases)
    func psbtChainGetsThePsbtValidator(blockchain: PsbtBlockchain) throws {
        let validator = makeSUT(blockchain: blockchain.blockchain).makeValidator()

        #expect(validator is PsbtSwapTransactionValidator)
    }

    @Test("Every other chain keeps the wallet's own validator", arguments: NonPsbtBlockchain.allCases)
    func otherChainKeepsTheWalletValidator(blockchain: NonPsbtBlockchain) throws {
        let validator = makeSUT(blockchain: blockchain.blockchain).makeValidator()

        #expect(validator is BSDKTransactionValidator)
    }
}

// MARK: - SUT

private extension SendTransactionValidatorFactoryTests {
    func makeSUT(blockchain: Blockchain) -> SendTransactionValidatorFactory {
        SendTransactionValidatorFactory(
            blockchain: blockchain,
            transactionValidator: TransactionValidatorStub(blockchain: blockchain)
        )
    }
}

// MARK: - Fixtures

/// Every chain whose DEX swap is signed from a provider-built PSBT.
enum PsbtBlockchain: CaseIterable, Sendable {
    case bitcoin
    case litecoin
    case dogecoin
    case dash
    case bitcoinCash

    var blockchain: Blockchain {
        switch self {
        case .bitcoin: .bitcoin(testnet: false)
        case .litecoin: .litecoin
        case .dogecoin: .dogecoin
        case .dash: .dash(testnet: false)
        case .bitcoinCash: .bitcoinCash
        }
    }
}

/// Chains that swap through a DEX while we keep building the transaction ourselves.
enum NonPsbtBlockchain: CaseIterable, Sendable {
    case ethereum
    case bsc
    case polygon
    case tron

    var blockchain: Blockchain {
        switch self {
        case .ethereum: .ethereum(testnet: false)
        case .bsc: .bsc(testnet: false)
        case .polygon: .polygon(testnet: false)
        case .tron: .tron(testnet: false)
        }
    }
}

// MARK: - Stubs

private final class TransactionValidatorStub: TransactionValidator {
    var wallet: Wallet

    var walletPublisher: AnyPublisher<Wallet, Never> { Just(wallet).eraseToAnyPublisher() }

    init(blockchain: Blockchain) {
        // The secp256k1 generator point — a valid compressed key, so the address derivation succeeds.
        let publicKey = Wallet.PublicKey(
            seedKey: Data(hexString: "0279BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798"),
            derivationType: .none
        )

        wallet = try! WalletFactory(blockchain: blockchain).makeWallet(publicKey: publicKey)
    }
}
