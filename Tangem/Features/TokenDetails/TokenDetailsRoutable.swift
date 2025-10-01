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
    func openYieldModulePromoView(walletModel: any WalletModel, apy: String, signer: any TangemSigner)
    func openYieldEarnInfo(walletModel: any WalletModel, onGiveApproveAction: @escaping () -> Void, onStopEarnAction: @escaping () -> Void)
    func openYieldBalanceInfo(tokenName: String, tokenId: String?)
}
