//
//  HotSdk.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import LocalAuthentication
import TangemFoundation

public protocol HotSdk {
    /// Generates a new hot wallet.
    func generateWallet() throws -> UserWalletId
    /// Imports a hot wallet using the provided entropy and passphrase.
    func importWallet(entropy: Data, passphrase: String) throws -> UserWalletId

    /// Exports the mnemonic phrase for a hot wallet.
    func exportMnemonic(walletID: UserWalletId, auth: AuthenticationUnlockData) throws -> [String]
    /// Exports the backup data for a hot wallet.
    func exportBackup(walletID: UserWalletId, auth: AuthenticationUnlockData) throws -> Data

    /// Deletes a hot wallet.
    func delete(id: UserWalletId) throws

    /// Updates the accessCode for a hot wallet.
    ///  - Parameters:
    /// - `newAccessCode`: The new accessCode to set for the wallet.
    /// - `oldAuth`: The old accessCode or biometrics to unlock encrypted data. (could be nil if the wallet is not protected by accessCode yet)
    /// - `walletID`: The identifier of the wallet for which the accessCode is being updated.
    ///  - Throws: An error if the accessCode update fails, such as if
    /// the old authentication data is incorrect or if the wallet is missing
    func updateAccessCode(_ newAccessCode: String, oldAuth: AuthenticationUnlockData, for walletID: UserWalletId) throws

    /// Enables biometrics for a hot wallet.
    /// - Parameters:
    /// - `walletID`: The identifier of the wallet for which biometrics are being enabled.
    /// - `accessCode`: The accessCode to unlock encrypted data before enabling biometrics.
    /// - `context`: The `LAContext` used for biometric authentication.
    /// - Throws: An error if enabling biometrics fails, such as if the wallet is missing or the accessCode is incorrect.
    func enableBiometrics(for walletID: UserWalletId, accessCode: String, context: LAContext) throws

    /// Derives master keys for a hot wallet.
    /// - Parameters:
    /// - `walletID`: The identifier of the wallet for which master keys are being derived
    /// - `auth`: The authentication data used to unlock the wallet, such as a accessCode or biometrics.
    /// - Returns: A `HotWallet` object containing the derived master keys.
    func deriveMasterKeys(walletID: UserWalletId, auth: AuthenticationUnlockData) throws -> HotWallet

    /// Derives keys for a hot wallet based on specified derivation paths.
    /// - Parameters:
    /// - `wallet`: The hot wallet for which keys are being derived.
    /// - `auth`: The authentication data used to unlock the wallet, such as a accessCode or biometrics.
    /// - `derivationPaths`: A dictionary mapping key types to their respective derivation paths
    /// - Returns: A `HotWallet` object containing the derived keys.
    func deriveKeys(
        walletID: UserWalletId,
        auth: AuthenticationUnlockData,
        derivationPaths: [Data: [DerivationPath]]
    ) throws -> [Data: HotWalletKeyInfo]
}
