//
//  SwapRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol SwapRoutable {
    func openSwapTokenSelector(
        swapTokenSelectorViewModelBuilder: SwapTokenSelectorViewModelBuilder,
        direction: SwapTokenSelectorViewModel.SwapDirection
    )
}
