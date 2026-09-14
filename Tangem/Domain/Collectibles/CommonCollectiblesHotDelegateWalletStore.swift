//
//  CommonCollectiblesHotDelegateWalletStore.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemMobileWalletSdk
import TangemSdk

/// Holds the hot delegate as a throwaway unprotected mobile wallet — no access code, no biometrics — so
/// reads and signing stay silent. Real wallets map to their delegate wallets through an id table in settings.
final class CommonCollectiblesHotDelegateWalletStore: CollectiblesHotDelegateWalletStore {
    enum KeyError: Error {
        case keyMissing
        case masterKeyUnavailable
        case signingFailed
    }

    private let sdk: any MobileWalletSdk
    private let walletIdStore: any CollectiblesHotDelegateWalletIdStore
    private let masterPublicKeys = OSAllocatedUnfairLock<[UserWalletId: Data]>(initialState: [:])

    init(
        sdk: any MobileWalletSdk = CommonMobileWalletSdk(),
        walletIdStore: any CollectiblesHotDelegateWalletIdStore = KeychainCollectiblesHotDelegateWalletIdStore()
    ) {
        self.sdk = sdk
        self.walletIdStore = walletIdStore
    }

    func generateKey(for userWalletId: UserWalletId) throws -> Data {
        let previousDelegateWalletId = try walletIdStore.delegateWalletId(for: userWalletId)
        let delegateWalletId = try sdk.generateWallet()

        let publicKey: Data

        do {
            let context = try sdk.validate(auth: .none, for: delegateWalletId)
            publicKey = try masterPublicKey(delegateWalletId: delegateWalletId, context: context)
            try walletIdStore.setDelegateWalletId(delegateWalletId, for: userWalletId)
        } catch {
            try? sdk.delete(walletIDs: [delegateWalletId])
            throw error
        }

        // The replaced key is dead the moment the mapping moves on; failing to erase it is not a failure
        if let previousDelegateWalletId {
            try? sdk.delete(walletIDs: [previousDelegateWalletId])
            masterPublicKeys.withLock { $0[previousDelegateWalletId] = nil }
        }

        return publicKey
    }

    func publicKey(for userWalletId: UserWalletId) throws -> Data? {
        guard let delegateWalletId = try walletIdStore.delegateWalletId(for: userWalletId) else {
            return nil
        }

        return try heldMasterPublicKey(delegateWalletId: delegateWalletId)
    }

    func sign(_ message: Data, for userWalletId: UserWalletId) throws -> Data {
        guard let delegateWalletId = try walletIdStore.delegateWalletId(for: userWalletId) else {
            throw KeyError.keyMissing
        }

        let context = try sdk.validate(auth: .none, for: delegateWalletId)
        let publicKey = try masterPublicKey(delegateWalletId: delegateWalletId, context: context)
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
        guard let delegateWalletId = try walletIdStore.delegateWalletId(for: userWalletId) else {
            return
        }

        try sdk.delete(walletIDs: [delegateWalletId])
        try walletIdStore.setDelegateWalletId(nil, for: userWalletId)
        masterPublicKeys.withLock { $0[delegateWalletId] = nil }
    }
}

// MARK: - Private implementation

private extension CommonCollectiblesHotDelegateWalletStore {
    /// `nil` once the mapping outlives the wallet it names: settings come back on a restored device, the
    /// key behind them stays on the old one.
    func heldMasterPublicKey(delegateWalletId: UserWalletId) throws -> Data? {
        if let cached = masterPublicKeys.withLock({ $0[delegateWalletId] }) {
            return cached
        }

        guard let context = try? sdk.validate(auth: .none, for: delegateWalletId) else {
            return nil
        }

        return try masterPublicKey(delegateWalletId: delegateWalletId, context: context)
    }

    func masterPublicKey(delegateWalletId: UserWalletId, context: MobileWalletContext) throws -> Data {
        if let cached = masterPublicKeys.withLock({ $0[delegateWalletId] }) {
            return cached
        }

        let wallet = try sdk.deriveMasterKeys(context: context)

        guard let masterKey = wallet.wallets.first(where: { $0.curve == .ed25519 })?.publicKey else {
            throw KeyError.masterKeyUnavailable
        }

        masterPublicKeys.withLock { $0[delegateWalletId] = masterKey }

        return masterKey
    }
}
