//
//  SwappingRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import TangemFoundation

protocol ExpressRoutable: AnyObject {
    func presentSwappingTokenList(swapDirection: ExpressTokensListViewModel.SwapDirection)
    func presentSwapTokenSelector(swapDirection: SwapTokenSelectorViewModel.SwapDirection)
    func presentFeeSelectorView(source: any ExpressInteractorSourceWallet)
    func presentApproveView(source: any ExpressInteractorSourceWallet, provider: ExpressProvider, selectedPolicy: BSDKApprovePolicy)
    func presentProviderSelectorView()
    func presentFeeCurrency(feeCurrency: FeeCurrencyNavigatingDismissOption)
    func presentSuccessView(data: SentExpressTransactionData)
    func closeSwappingView()
}
