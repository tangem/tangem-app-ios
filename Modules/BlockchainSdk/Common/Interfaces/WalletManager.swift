//
//  WalletManager.swift
//  blockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import Combine

public protocol WalletManager: BaseWalletManagerObject,
    BlockchainDataProvider,
    TransactionSender,
    TransactionCreator,
    TransactionFeeProvider,
    YieldSupplyServiceProvider,
    TransactionValidator {}

// MARK: - BlockchainDataProvider

public protocol BlockchainDataProvider {
    var currentHost: String { get }
    var outputsCount: Int? { get }
}

extension BlockchainDataProvider {
    var outputsCount: Int? { return nil }
}

// MARK: - TransactionSender

public protocol TransactionSender {
    func send(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<TransactionSendResult, SendTxError>
}

// MARK: - MultipleTransactionSender

/// transactions expected to be signed in one tap and sent in initially provided order
public protocol MultipleTransactionsSender {
    func send(
        _ transactions: [Transaction],
        signer: TransactionSigner
    ) -> AnyPublisher<[TransactionSendResult], SendTxError>
}

public protocol CompiledTransactionSender {
    func send(compiledTransaction data: Data, signer: TransactionSigner) async throws -> TransactionSendResult
}

public protocol BitcoinPsbtSwapSender {
    func send(psbtBase64: String, destination: String, signer: TransactionSigner) async throws -> TransactionSendResult
}

// MARK: - TransactionSigner

public protocol TransactionSigner {
    func sign(hashes: [Data], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[SignatureInfo], Error>
    func sign(hash: Data, walletPublicKey: Wallet.PublicKey) -> AnyPublisher<SignatureInfo, Error>
    func sign(dataToSign: [SignData], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[SignatureInfo], Error>
}

public extension TransactionSigner {
    func sign(hash: Data, walletPublicKey: Wallet.PublicKey) -> AnyPublisher<Data, Error> {
        sign(hash: hash, walletPublicKey: walletPublicKey)
            .map { $0.signature }
            .eraseToAnyPublisher()
    }

    func sign(hashes: [Data], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[Data], Error> {
        sign(hashes: hashes, walletPublicKey: walletPublicKey)
            .map { $0.map { $0.signature } }
            .eraseToAnyPublisher()
    }
}

// MARK: - AddressResolver

public protocol AddressResolver {
    func requiresResolution(address: String) -> Bool
    func resolve(_ address: String) async throws -> AddressResolverResult
}

public struct AddressResolverResult {
    public let resolved: String
    public let requiresDestinationTag: Bool

    public init(resolved: String, requiresDestinationTag: Bool = false) {
        self.resolved = resolved
        self.requiresDestinationTag = requiresDestinationTag
    }
}

// MARK: - DomainNameAddressResolver

public protocol DomainNameAddressResolver {
    func resolveDomainName(_ address: String) async throws -> String
}

// MARK: - AssetRequirementsManager

/// Responsible for the token association creation (Hedera) and trust line setup (XRP, Stellar, Aptos, Algorand and other).
@available(iOS 13.0, *)
public protocol AssetRequirementsManager {
    typealias Asset = Amount.AmountType

    func requirementsCondition(for asset: Asset) -> AssetRequirementsCondition?
    func fulfillRequirements(for asset: Asset, signer: any TransactionSigner) -> AnyPublisher<Void, Error>
    /// - Note: The default implementation of this method does nothing.
    func discardRequirements(for asset: Asset)
    func feeStatusForRequirement(asset: Asset) -> AnyPublisher<AssetRequirementFeeStatus, Never>
}

extension AssetRequirementsManager {
    func discardRequirements(for asset: Asset) {
        // No-op
    }
}

// MARK: - MinimalBalanceProvider

public protocol MinimalBalanceProvider {
    func minimalBalance() -> Decimal
}
