//
//  UnlockHotWallet.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct HotWalletAuthInfo {
    public let walletID: HotWalletID
    public let auth: HotAuth?

    public init?(walletID: HotWalletID, auth: HotAuth?) {
        switch (walletID.authType, auth) {
        case (.none, .password?),
             (.password?, .biometrics?), (.password?, .password?),
             (.biometrics?, .biometrics?):
            self.walletID = walletID
            self.auth = auth
        default: return nil
        }
    }
}
