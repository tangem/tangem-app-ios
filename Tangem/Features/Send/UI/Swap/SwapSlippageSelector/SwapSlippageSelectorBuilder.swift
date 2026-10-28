//
//  SwapSlippageSelectorBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct SwapSlippageSelectorBuilder {
    let slippageInput: any SwapSlippageInput
    let slippageOutput: any SwapSlippageOutput

    func makeSlippageSelector() -> SwapSlippageSelectorViewModel? {
        guard let providerSlippage = slippageInput.providerSlippage else {
            return nil
        }

        slippageOutput.userDidOpenSlippageSelector()

        return SwapSlippageSelectorViewModel(
            providerSlippage: providerSlippage,
            slippage: slippageInput.slippage,
            output: slippageOutput
        )
    }
}
