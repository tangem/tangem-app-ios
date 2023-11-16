//
//  SwappingModulesFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemSwapping

protocol SwappingModulesFactory {
    func makeExpressViewModel(coordinator: ExpressRoutable) -> ExpressViewModel
    func makeSwappingViewModel(coordinator: SwappingRoutable) -> SwappingViewModel
    func makeExpressTokensListViewModel(
        walletType: ExpressTokensListViewModel.SwapDirection,
        coordinator: ExpressTokensListRoutable
    ) -> ExpressTokensListViewModel
    func makeSwappingTokenListViewModel(coordinator: SwappingTokenListRoutable) -> SwappingTokenListViewModel
    func makeExpressFeeSelectorViewModel(coordinator: ExpressFeeBottomSheetRoutable) -> ExpressFeeBottomSheetViewModel
    func makeSwappingApproveViewModel(coordinator: SwappingApproveRoutable) -> SwappingApproveViewModel

    func makeSwappingSuccessViewModel(
        inputModel: SwappingSuccessInputModel,
        coordinator: SwappingSuccessRoutable
    ) -> SwappingSuccessViewModel
}
