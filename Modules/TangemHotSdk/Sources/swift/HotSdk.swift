//
//  HotSdk.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public protocol HotSdk {
    func importWallet(entropy: Data, passphrase: String?, auth: HotAuth?) throws -> HotWalletID
    func generateWallet(auth: HotAuth?) throws -> HotWalletID

    func exportMnemonic(walletAuthInfo: HotWalletAuthInfo) async throws -> PrivateInfo
    func exportBackup(walletAuthInfo: HotWalletAuthInfo) async throws -> Data

    func delete(id: HotWalletID) async throws
    func changeAuth(walletAuthInfo: HotWalletAuthInfo, auth: HotAuth) async throws
}
