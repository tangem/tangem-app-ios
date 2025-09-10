//
//  TokenDetailsRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol TokenDetailsRoutable: AnyObject {
    func dismiss()
    func openFeeCurrency(for model: any WalletModel, userWalletModel: UserWalletModel)
    func openYieldModulePromoView(walletModel: any WalletModel, info: YieldModuleInfo)
    func openYieldInfo(params: YieldModuleBottomSheetParams.EarnInfoParams, walletModel: any WalletModel)
}
