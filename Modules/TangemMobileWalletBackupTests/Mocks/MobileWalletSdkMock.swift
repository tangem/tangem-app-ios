//
//  MobileWalletSdkMock.swift
//  TangemMobileWalletBackupTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemSdk
@testable import TangemMobileWalletSdk

final class MobileWalletSdkMock: MobileWalletSdk {
    private let mnemonicWords: [String]
    private let passphrase: String

    init(mnemonicWords: [String], passphrase: String = "") {
        self.mnemonicWords = mnemonicWords
        self.passphrase = passphrase
    }

    func exportMnemonic(context: MobileWalletContext) throws -> [String] {
        mnemonicWords
    }

    func exportPassphrase(context: MobileWalletContext) throws -> String {
        passphrase
    }

    // MARK: - Unused protocol requirements

    func generateWallet() throws -> UserWalletId {
        fatalError("Not supported")
    }

    func importWallet(entropy: Data, passphrase: String) throws -> UserWalletId {
        fatalError("Not supported")
    }

    func validate(auth: AuthenticationUnlockData, for walletID: UserWalletId) throws -> MobileWalletContext {
        fatalError("Not supported")
    }

    func exportBackup(context: MobileWalletContext) throws -> Data {
        fatalError("Not supported")
    }

    func delete(walletIDs: [UserWalletId]) throws {
        fatalError("Not supported")
    }

    func updateAccessCode(
        _ newAccessCode: String,
        enableBiometrics: Bool,
        seedKey: Data,
        context: MobileWalletContext
    ) throws {
        fatalError("Not supported")
    }

    func refreshBiometrics(context: MobileWalletContext) throws {
        fatalError("Not supported")
    }

    func isBiometricsEnabled(for walletID: UserWalletId) -> Bool {
        fatalError("Not supported")
    }

    func clearBiometrics(walletIDs: [UserWalletId]) {
        fatalError("Not supported")
    }

    func deriveMasterKeys(context: MobileWalletContext) throws -> MobileWallet {
        fatalError("Not supported")
    }

    func deriveKeys(
        context: MobileWalletContext,
        derivationPaths: [Data: [DerivationPath]]
    ) throws -> [Data: MobileWalletKeyInfo] {
        fatalError("Not supported")
    }

    func sign(
        dataToSign: [SignData],
        seedKey: Data,
        context: MobileWalletContext
    ) throws -> [MobileWalletSignature] {
        fatalError("Not supported")
    }

    func userWalletEncryptionKey(context: MobileWalletContext) throws -> UserWalletEncryptionKey {
        fatalError("Not supported")
    }
}
