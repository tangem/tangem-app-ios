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
    var providerSlippage: SwapProviderSlippage? { get }
    var providerSlippagePublisher: AnyPublisher<SwapProviderSlippage?, Never> { get }
    var isCustomSlippageResetPublisher: AnyPublisher<Bool, Never> { get }
}

protocol SwapSlippageOutput: AnyObject {
    func userDidOpenSlippageSelector()
    func userDidSet(slippage: SwapSlippage)
}
