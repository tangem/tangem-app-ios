//
//  SwappingRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

protocol ExpressRoutable: AnyObject {
    func presentSwappingTokenList(swapDirection: ExpressTokensListViewModel.SwapDirection)
    func presentFeeSelectorView()
    func presentApproveView()
    func presentProviderSelectorView()
    func presentNetworkCurrency(for walletModel: WalletModel, userWalletModel: UserWalletModel)
    func presentSuccessView(data: SentExpressTransactionData)
}
