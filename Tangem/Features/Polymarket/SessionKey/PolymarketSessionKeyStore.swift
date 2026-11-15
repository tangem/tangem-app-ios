//
//  PolymarketSessionKeyStore.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation
import TangemMobileWalletSdk
import TangemPolymarket
import TangemSdk

protocol PolymarketSessionKeyStore {
    func heldAddress(for userWalletId: UserWalletId) throws -> String?

    func generateKey(for userWalletId: UserWalletId) throws -> String

    func sign(hash: Data, for userWalletId: UserWalletId) throws -> String

    func deleteKey(for userWalletId: UserWalletId) throws
}

final class CommonPolymarketSessionKeyStore {
    enum KeyError: Error {
        case keyMissing
        case masterKeyUnavailable
        case signingFailed
    }

    private let sdk: any MobileWalletSdk
    private let secureStorage: any PolymarketSecureStorage
    private let publicKeys = OSAllocatedUnfairLock<[UserWalletId: Data]>(initialState: [:])
    private let criticalSection = OSAllocatedUnfairLock()

    init(sdk: any MobileWalletSdk = CommonMobileWalletSdk(), secureStorage: any PolymarketSecureStorage = SecureStorage()) {
        self.sdk = sdk
        self.secureStorage = secureStorage
    }
}

// MARK: - PolymarketSessionKeyStore protocol conformance

extension CommonPolymarketSessionKeyStore: PolymarketSessionKeyStore {
    func heldAddress(for userWalletId: UserWalletId) throws -> String? {
        guard let keyWalletId = try storedKeyWalletId(for: userWalletId) else {
            return nil
        }

        return try makeAddress(publicKey: heldPublicKey(keyWalletId: keyWalletId))
    }

    func generateKey(for userWalletId: UserWalletId) throws -> String {
        try criticalSection {
            let previousKeyWalletId = try storedKeyWalletId(for: userWalletId)
            let keyWalletId = try sdk.generateWallet()

            let address: String

            do {
                let context = try sdk.validate(auth: .none, for: keyWalletId)
                address = try makeAddress(publicKey: publicKey(keyWalletId: keyWalletId, context: context))
                try secureStorage.store(keyWalletId.value, forKey: account(for: userWalletId), overwrite: true)
            } catch {
                try? sdk.delete(walletIDs: [keyWalletId])
                publicKeys.withLock { $0[keyWalletId] = nil }
                throw error
            }

            if let previousKeyWalletId {
                try? sdk.delete(walletIDs: [previousKeyWalletId])
                publicKeys.withLock { $0[previousKeyWalletId] = nil }
            }

            return address
        }
    }

    func sign(hash: Data, for userWalletId: UserWalletId) throws -> String {
        guard let keyWalletId = try storedKeyWalletId(for: userWalletId) else {
            throw KeyError.keyMissing
        }

        let context = try sdk.validate(auth: .none, for: keyWalletId)
        let publicKey = try publicKey(keyWalletId: keyWalletId, context: context)

        let signatures = try sdk.sign(
            dataToSign: [SignData(derivationPath: nil, hashes: [hash], publicKey: publicKey)],
            seedKey: publicKey,
            context: context
        )

        guard let signature = signatures.first?.signature else {
            throw KeyError.signingFailed
        }

        return try SignatureInfo(signature: signature, publicKey: publicKey, hash: hash)
            .unmarshal()
            .hexString
            .lowercased()
            .addHexPrefix()
    }

    func deleteKey(for userWalletId: UserWalletId) throws {
        try criticalSection {
            guard let keyWalletId = try storedKeyWalletId(for: userWalletId) else {
                return
            }

            publicKeys.withLock { $0[keyWalletId] = nil }
            try sdk.delete(walletIDs: [keyWalletId])
            try secureStorage.delete(account(for: userWalletId))
        }
    }
}

// MARK: - Private implementation

private extension CommonPolymarketSessionKeyStore {
    func storedKeyWalletId(for userWalletId: UserWalletId) throws -> UserWalletId? {
        try secureStorage.get(account(for: userWalletId)).map(UserWalletId.init(value:))
    }

    func heldPublicKey(keyWalletId: UserWalletId) throws -> Data {
        if let cached = publicKeys.withLock({ $0[keyWalletId] }) {
            return cached
        }

        let context = try sdk.validate(auth: .none, for: keyWalletId)
        return try publicKey(keyWalletId: keyWalletId, context: context)
    }

    func publicKey(keyWalletId: UserWalletId, context: MobileWalletContext) throws -> Data {
        if let cached = publicKeys.withLock({ $0[keyWalletId] }) {
            return cached
        }

        let wallet = try sdk.deriveMasterKeys(context: context)

        guard let publicKey = wallet.wallets.first(where: { $0.curve == PolymarketUtilities.mandatoryCurve })?.publicKey else {
            throw KeyError.masterKeyUnavailable
        }

        publicKeys.withLock { $0[keyWalletId] = publicKey }

        return publicKey
    }

    func makeAddress(publicKey: Data) throws -> String {
        try PolymarketUtilities.makeAddress(using: Wallet.PublicKey(seedKey: publicKey, derivationType: nil)).lowercased()
    }

    func account(for userWalletId: UserWalletId) -> String {
        Constants.accountPrefix + userWalletId.stringValue.lowercased()
    }

    enum Constants {
        static let accountPrefix = "polymarket_session_key_wallet_id_"
    }
}
