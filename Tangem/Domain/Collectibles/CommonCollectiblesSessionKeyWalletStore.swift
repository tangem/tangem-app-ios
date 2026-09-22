//
//  CommonCollectiblesSessionKeyWalletStore.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemMobileWalletSdk
import TangemSdk

/// Holds the session key as a mobile wallet of its own, so signing a spin prompts for nothing. A wallet
/// finds its session key wallet through an id table.
final class CommonCollectiblesSessionKeyWalletStore: CollectiblesSessionKeyWalletStore {
    enum KeyError: Error {
        case keyMissing
        case masterKeyUnavailable
        case signingFailed
    }

    private let sdk: any MobileWalletSdk
    private let walletIdStore: any CollectiblesSessionKeyWalletIdStore
    private let masterPublicKeys = OSAllocatedUnfairLock<[UserWalletId: Data]>(initialState: [:])

    init(
        sdk: any MobileWalletSdk = CommonMobileWalletSdk(),
        walletIdStore: any CollectiblesSessionKeyWalletIdStore = KeychainCollectiblesSessionKeyWalletIdStore()
    ) {
        self.sdk = sdk
        self.walletIdStore = walletIdStore
    }

    func generateKey(for userWalletId: UserWalletId) throws -> Data {
        let previousSessionKeyWalletId = try walletIdStore.sessionKeyWalletId(for: userWalletId)
        let sessionKeyWalletId = try sdk.generateWallet()

        let publicKey: Data

        do {
            let context = try sdk.validate(auth: .none, for: sessionKeyWalletId)
            publicKey = try masterPublicKey(sessionKeyWalletId: sessionKeyWalletId, context: context)
            try walletIdStore.setSessionKeyWalletId(sessionKeyWalletId, for: userWalletId)
        } catch {
            try? sdk.delete(walletIDs: [sessionKeyWalletId])
            throw error
        }

        // The replaced key is dead the moment the mapping moves on; failing to erase it is not a failure
        if let previousSessionKeyWalletId {
            try? sdk.delete(walletIDs: [previousSessionKeyWalletId])
            masterPublicKeys.withLock { $0[previousSessionKeyWalletId] = nil }
        }

        return publicKey
    }

    func publicKey(for userWalletId: UserWalletId) throws -> Data? {
        guard let sessionKeyWalletId = try walletIdStore.sessionKeyWalletId(for: userWalletId) else {
            return nil
        }

        return try heldMasterPublicKey(sessionKeyWalletId: sessionKeyWalletId)
    }

    func sign(_ message: Data, for userWalletId: UserWalletId) throws -> Data {
        guard let sessionKeyWalletId = try walletIdStore.sessionKeyWalletId(for: userWalletId) else {
            throw KeyError.keyMissing
        }

        let context = try sdk.validate(auth: .none, for: sessionKeyWalletId)
        let publicKey = try masterPublicKey(sessionKeyWalletId: sessionKeyWalletId, context: context)
        let signatures = try sdk.sign(
            dataToSign: [SignData(derivationPath: nil, hashes: [message], publicKey: publicKey)],
            seedKey: publicKey,
            context: context
        )

        guard let signature = signatures.first?.signature else {
            throw KeyError.signingFailed
        }

        return signature
    }

    func deleteKey(for userWalletId: UserWalletId) throws {
        guard let sessionKeyWalletId = try walletIdStore.sessionKeyWalletId(for: userWalletId) else {
            return
        }

        try sdk.delete(walletIDs: [sessionKeyWalletId])
        try walletIdStore.setSessionKeyWalletId(nil, for: userWalletId)
        masterPublicKeys.withLock { $0[sessionKeyWalletId] = nil }
    }
}

// MARK: - Private implementation

private extension CommonCollectiblesSessionKeyWalletStore {
    /// `nil` once the mapping outlives the wallet it names: settings come back on a restored device, the
    /// key behind them stays on the old one.
    func heldMasterPublicKey(sessionKeyWalletId: UserWalletId) throws -> Data? {
        if let cached = masterPublicKeys.withLock({ $0[sessionKeyWalletId] }) {
            return cached
        }

        guard let context = try? sdk.validate(auth: .none, for: sessionKeyWalletId) else {
            return nil
        }

        return try masterPublicKey(sessionKeyWalletId: sessionKeyWalletId, context: context)
    }

    func masterPublicKey(sessionKeyWalletId: UserWalletId, context: MobileWalletContext) throws -> Data {
        if let cached = masterPublicKeys.withLock({ $0[sessionKeyWalletId] }) {
            return cached
        }

        let wallet = try sdk.deriveMasterKeys(context: context)

        guard let masterKey = wallet.wallets.first(where: { $0.curve == .ed25519 })?.publicKey else {
            throw KeyError.masterKeyUnavailable
        }

        masterPublicKeys.withLock { $0[sessionKeyWalletId] = masterKey }

        return masterKey
    }
}
