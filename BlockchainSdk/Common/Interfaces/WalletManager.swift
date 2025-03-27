//
//  Walletmanager.swift
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
    TransactionValidator {}

public enum WalletManagerState {
    case initial
    case loading
    case loaded
    case failed(Error)

    public var isInitialState: Bool {
        switch self {
        case .initial:
            return true
        default:
            return false
        }
    }

    public var isLoading: Bool {
        switch self {
        case .loading:
            return true
        default:
            return false
        }
    }
}

// MARK: - WalletProvider

public protocol WalletProvider: AnyObject {
    var wallet: Wallet { get set }
    var walletPublisher: AnyPublisher<Wallet, Never> { get }
    var statePublisher: AnyPublisher<WalletManagerState, Never> { get }
}

extension WalletProvider {
    var defaultSourceAddress: String { wallet.address }
    var defaultChangeAddress: String { wallet.address }
}

// MARK: - WalletUpdater

public protocol WalletUpdater: AnyObject {
    func setNeedsUpdate()
    func updatePublisher() -> AnyPublisher<Void, Never>
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

// MARK: - TransactionSigner

public protocol TransactionSigner {
    func sign(hashes: [Data], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[Data], Error>
    func sign(hash: Data, walletPublicKey: Wallet.PublicKey) -> AnyPublisher<Data, Error>
}

extension TransactionSigner {
    func sign(hash: Data, walletPublicKey: Wallet.PublicKey) -> AnyPublisher<SignatureInfo, Error> {
        sign(hash: hash, walletPublicKey: walletPublicKey)
            .map { signature in
                SignatureInfo(signature: signature, publicKey: walletPublicKey.blockchainKey, hash: hash)
            }
            .eraseToAnyPublisher()
    }

    func sign(hashes: [Data], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[SignatureInfo], Error> {
        sign(hashes: hashes, walletPublicKey: walletPublicKey)
            .map { signatures in
                zip(hashes, signatures).map { hash, signature in
                    SignatureInfo(signature: signature, publicKey: walletPublicKey.blockchainKey, hash: hash)
                }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - AddressResolver

@available(iOS 13.0, *)
public protocol AddressResolver {
    func resolve(_ address: String) async throws -> String
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
}

extension AssetRequirementsManager {
    func discardRequirements(for asset: Asset) {
        // No-op
    }
}
