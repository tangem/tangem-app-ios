//
//  WCFeeInteractorType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemFoundation

struct WCFee {
    let option: FeeOption
    let value: LoadingValue<Fee>

    init(option: FeeOption, value: LoadingValue<Fee>) {
        self.option = option
        self.value = value
    }
}

extension WCFee: CustomStringConvertible {
    var description: String {
        return "WCFee(option: \(option), value: \(value))"
    }
}

protocol WCFeeInteractorType {
    var selectedFee: WCFee { get }
    var fees: [WCFee] { get }
    var selectedFeePublisher: AnyPublisher<WCFee, Never> { get }
    var customFeeService: WCCustomEvmFeeService { get }

    func retryFeeLoading()
}

protocol WCFeeInteractorOutput: AnyObject {
    func feeDidChanged(fee: WCFee)
    func returnToTransactionDetails()
}
