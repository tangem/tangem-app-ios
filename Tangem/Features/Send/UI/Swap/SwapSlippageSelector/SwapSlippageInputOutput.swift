//
//  SwapSlippageInputOutput.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation

protocol SwapSlippageInput: AnyObject {
    var slippage: SwapSlippage { get }
    var slippagePublisher: AnyPublisher<SwapSlippage, Never> { get }
}

protocol SwapSlippageOutput: AnyObject {
    func userDidSet(slippage: SwapSlippage)
}
