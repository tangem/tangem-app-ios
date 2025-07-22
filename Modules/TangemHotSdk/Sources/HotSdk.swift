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
    func importWallet(entropy: Data, passphrase: String, auth: Authentication) throws -> HotWalletID
    func generateWallet(auth: Authentication) throws -> HotWalletID

    func exportMnemonic(walletID: HotWalletID, auth: AuthenticationUnlockData) throws -> PrivateInfo
    func exportBackup(walletID: HotWalletID, auth: AuthenticationUnlockData) throws -> Data

    func delete(id: HotWalletID) throws
    
    func updateAuthentication(
        _ newAuth: Authentication?,
        oldAuth: AuthenticationUnlockData?,
        for walletID: HotWalletID
    ) throws
}
