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
        guard let provider = slippageInput.slippageProvider else {
            return nil
        }

        return SwapSlippageSelectorViewModel(
            provider: provider,
            slippage: slippageInput.slippage,
            output: slippageOutput
        )
    }
}
