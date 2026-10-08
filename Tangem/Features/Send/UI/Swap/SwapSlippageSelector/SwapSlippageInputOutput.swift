//
//  SwapSlippageInputOutput.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemExpress

protocol SwapSlippageInput: AnyObject {
    var slippage: SwapSlippage { get }
    var slippagePublisher: AnyPublisher<SwapSlippage, Never> { get }
    var slippageProvider: ExpressProvider? { get }
    var slippageProviderPublisher: AnyPublisher<ExpressProvider?, Never> { get }
}

protocol SwapSlippageOutput: AnyObject {
    func userDidSet(slippage: SwapSlippage)
}
