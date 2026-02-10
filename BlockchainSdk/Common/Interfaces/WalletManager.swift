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

public protocol WalletManager: WalletProvider,
    TokensWalletProvider,
    WalletUpdater,
    BlockchainDataProvider,
    TransactionSender,
    TransactionCreator,
    TransactionFeeProvider,
    YieldSupplyServiceProvider,
    TransactionValidator {}

// MARK: - WalletProvider

public protocol WalletProvider: AnyObject {
    var wallet: Wallet { get set }
    var state: WalletManagerState { get }

    var walletPublisher: AnyPublisher<Wallet, Never> { get }
    var statePublisher: AnyPublisher<WalletManagerState, Never> { get }
}

extension WalletProvider {
    var defaultSourceAddress: String { wallet.address }
    var defaultChangeAddress: String { wallet.address }
}

public enum WalletManagerState {
    case initial
    case loading
    case loaded
    case failed(Error)
}

// MARK: - WalletUpdater

public protocol WalletUpdater: AnyObject {
    /// Reset the last updating time
    func setNeedsUpdate()
    func update() async
}

// MARK: - TokensWalletProvider

public protocol TokensWalletProvider {
    var cardTokens: [Token] { get }

    func removeToken(_ token: Token)
    func addToken(_ token: Token)
}

public extension TokensWalletProvider {
    func addTokens(_ tokens: [Token]) {
        tokens.forEach { addToken($0) }
    }
}

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

@available(iOS 13.0, *)
public protocol AddressResolver {
    func requiresResolution(address: String) -> Bool
    func resolve(_ address: String) async throws -> String
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
