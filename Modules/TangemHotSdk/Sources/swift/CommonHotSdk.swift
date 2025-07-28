//
//  DefaultTangemHotSdk.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import LocalAuthentication

public final class CommonHotSdk: HotSdk {
    private let privateInfoStorage: PrivateInfoStorage
    
    public convenience init() {
        self.init(
            secureStorage: SecureStorage(),
            secureEnclaveService: SecureEnclaveService(config: .default)
        )
    }

    init(
        secureStorage: HotSecureStorage,
        secureEnclaveService: HotSecureEnclaveService
    ) {
        privateInfoStorage = PrivateInfoStorage(
            secureStorage: secureStorage,
            accessCodeSecureEnclaveService: secureEnclaveService
        )
    }

    public func importWallet(entropy: Data, passphrase: String) throws -> HotWalletID {
        let walletID = HotWalletID()

        try privateInfoStorage.storeUnsecured(
            privateInfoData: PrivateInfo(entropy: entropy, passphrase: passphrase).encode(),
            walletID: walletID
        )
        return walletID
    }

    public func generateWallet() throws -> HotWalletID {
        let entropy = try CryptoUtils.generateRandomBytes(count: 32) // 256 bits of entropy

        return try importWallet(entropy: entropy, passphrase: "")
    }

    public func exportPrivateInfo(walletID: HotWalletID, auth: AuthenticationUnlockData) throws -> PrivateInfo {
        let privateInfo = try privateInfoStorage.getPrivateInfoData(for: walletID, auth: auth)

        guard let privateInfo = PrivateInfo(data: privateInfo) else {
            throw HotWalletError.failedToExportMnemonic
        }

        return privateInfo
    }

    public func exportBackup(walletID: HotWalletID, auth: AuthenticationUnlockData) throws -> Data {
        // Placeholder for backup export logic
        return Data()
    }

    public func delete(id: HotWalletID) throws {
        try privateInfoStorage.delete(hotWalletID: id)
    }

    public func updateAccessCode(_ newAccessCode: String, oldAuth: AuthenticationUnlockData?, for walletID: HotWalletID) throws {
        try privateInfoStorage.updateAccessCode(newAccessCode, oldAuth: oldAuth, for: walletID)
    }

    public func enableBiometrics(for walletID: HotWalletID, accessCode: String, context: LAContext) throws {
        try privateInfoStorage.enableBiometrics(for: walletID, accessCode: accessCode, context: context)
    }

    public func deriveMasterKeys(walletID: HotWalletID, auth: AuthenticationUnlockData?) throws -> HotWallet {
        let privateInfo = try privateInfoStorage.getPrivateInfoData(for: walletID, auth: auth)

        guard let privateInfo = PrivateInfo(data: privateInfo) else {
            throw HotWalletError.failedToDeriveKey
        }

        defer {
            privateInfo.clear()
        }

        let keyInfos = try EllipticCurve.allCases.compactMap { curve -> HotWalletKeyInfo? in
            let publicKey: ExtendedPublicKey
            switch curve {
            case .bls12381_G2_AUG:
                publicKey = try BLSUtil.publicKey(entropy: privateInfo.entropy, passphrase: privateInfo.passphrase)
            case .secp256k1, .ed25519, .ed25519_slip0010:
                publicKey = try DerivationUtil.deriveKeys(
                    entropy: privateInfo.entropy,
                    passphrase: privateInfo.passphrase,
                    derivationPath: nil,
                    curve: curve
                )
            default:
                return nil
            }

            return HotWalletKeyInfo(
                publicKey: publicKey.publicKey,
                chainCode: publicKey.chainCode,
                curve: curve
            )
        }

        return HotWallet(
            id: walletID,
            wallets: keyInfos,
        )
    }

    public func deriveKeys(
        wallet: HotWallet,
        auth: AuthenticationUnlockData?,
        derivationPaths: [Data: [DerivationPath]]
    ) throws -> HotWallet {
        let privateInfo = try privateInfoStorage.getPrivateInfoData(for: wallet.id, auth: auth)

        guard let privateInfo = PrivateInfo(data: privateInfo) else {
            throw HotWalletError.failedToDeriveKey
        }

        defer {
            privateInfo.clear()
        }

        var wallets: [HotWalletKeyInfo] = wallet.wallets

        try derivationPaths.forEach { masterKey, derivationPaths in
            try derivationPaths.forEach { path in
                let derivedPublicKey = try DerivationUtil.deriveKeys(
                    entropy: privateInfo.entropy,
                    passphrase: privateInfo.passphrase,
                    derivationPath: path,
                    masterKey: masterKey
                )

                guard let walletIndex = wallet.wallets.firstIndex(where: { $0.publicKey == masterKey }) else {
                    return
                }
                wallets[walletIndex].derivedKeys[path] = derivedPublicKey
            }
        }

        return HotWallet(id: wallet.id, wallets: wallets)
    }
}
