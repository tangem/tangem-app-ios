//
//  MainQRScanTokenSelectorRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

@MainActor
protocol MainQRScanTokenSelectorRoutable: AnyObject {
    func didSelectToken(
        walletModel: any WalletModel,
        userWalletInfo: UserWalletInfo,
        sendParameters: PredefinedSendParameters
    )

    func closeTokenSelector()
}
