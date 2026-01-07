//
//  ExpressModulesFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

protocol ExpressModulesFactory {
    func makeExpressViewModel(coordinator: ExpressRoutable) -> ExpressViewModel
    func makeExpressTokensListViewModel(
        swapDirection: ExpressTokensListViewModel.SwapDirection,
        coordinator: ExpressTokensListRoutable
    ) -> ExpressTokensListViewModel

    func makeSwapTokenSelectorViewModel(
        swapDirection: SwapTokenSelectorViewModel.SwapDirection,
        coordinator: SwapTokenSelectorRoutable
    ) -> SwapTokenSelectorViewModel

    func makeExpressFeeSelectorViewModel(
        coordinator: ExpressFeeSelectorRoutable
    ) -> ExpressFeeSelectorViewModel

    func makeFeeSelectorViewModel(
        coordinator: FeeSelectorRoutable
    ) -> SendFeeSelectorViewModel

    func makeExpressApproveViewModel(
        source: any ExpressInteractorSourceWallet,
        providerName: String,
        selectedPolicy: BSDKApprovePolicy,
        coordinator: ExpressApproveRoutable
    ) -> ExpressApproveViewModel

    func makeExpressProvidersSelectorViewModel(coordinator: ExpressProvidersSelectorRoutable) -> ExpressProvidersSelectorViewModel

    func makeExpressSuccessSentViewModel(
        data: SentExpressTransactionData,
        coordinator: ExpressSuccessSentRoutable
    ) -> ExpressSuccessSentViewModel
}
