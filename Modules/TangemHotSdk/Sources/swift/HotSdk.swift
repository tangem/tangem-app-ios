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

public protocol HotSdk {
    /// Generates a new hot wallet.
    func generateWallet() throws -> HotWalletID
    /// Imports a hot wallet using the provided entropy and passphrase.
    func importWallet(entropy: Data, passphrase: String) throws -> HotWalletID

    func exportPrivateInfo(walletID: HotWalletID, auth: AuthenticationUnlockData) throws -> PrivateInfo
    func exportBackup(walletID: HotWalletID, auth: AuthenticationUnlockData) throws -> Data

    /// Deletes a hot wallet.
    func delete(id: HotWalletID) throws
    
    /// Updates the passcode for a hot wallet.
    ///  - Parameters:
    /// - `newPasscode`: The new passcode to set for the wallet.
    /// - `oldAuth`: The old passcode or biometrics to unlock encrypted data. (could be nil if the wallet is not protected by passcode yet)
    /// - `walletID`: The identifier of the wallet for which the passcode is being updated.
    ///  - Throws: An error if the passcode update fails, such as if
    /// the old authentication data is incorrect or if the wallet is missing
    func updatePasscode(_ newPasscode: String, oldAuth: AuthenticationUnlockData?, for walletID: HotWalletID) throws
    
    /// Enables biometrics for a hot wallet.
    /// - Parameters:
    /// - `walletID`: The identifier of the wallet for which biometrics are being enabled.
    /// - `passcode`: The passcode to unlock encrypted data before enabling biometrics.
    /// - Throws: An error if enabling biometrics fails, such as if the wallet is missing or the passcode is incorrect.
    func enableBiometrics(for walletID: HotWalletID, passcode: String) throws
}
