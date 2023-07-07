//
//  SwappingModulesFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemSwapping

protocol SwappingModulesFactory {
    func makeSwappingViewModel(coordinator: SwappingRoutable) -> SwappingViewModel
    func makeSwappingTokenListViewModel(coordinator: SwappingTokenListRoutable) -> SwappingTokenListViewModel
    func makeSwappingApproveViewModel(coordinator: SwappingApproveRoutable) -> SwappingApproveViewModel

    func makeSwappingSuccessViewModel(
        inputModel: SwappingSuccessInputModel,
        coordinator: SwappingSuccessRoutable
    ) -> SwappingSuccessViewModel
}
