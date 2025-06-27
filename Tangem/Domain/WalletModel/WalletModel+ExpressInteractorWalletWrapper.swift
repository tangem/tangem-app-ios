//
//  WalletModel+ExpressInteractorWalletWrapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress

extension WalletModel {
    var asExpressInteractorWallet: ExpressInteractorWalletWrapper {
        ExpressInteractorWalletWrapper(walletModel: self)
    }
}
