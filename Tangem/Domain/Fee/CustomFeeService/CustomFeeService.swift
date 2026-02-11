//
//  CustomFeeService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol CustomFeeService: AnyObject {
    func initialSetupCustomFee(_ fee: BSDKFee)

    func setup(output: CustomFeeServiceOutput)
}

protocol CustomFeeServiceInput: AnyObject {
    var cryptoAmountPublisher: AnyPublisher<Decimal, Never> { get }
    var destinationAddressPublisher: AnyPublisher<String, Never> { get }
}

protocol CustomFeeServiceOutput: AnyObject {
    /// There is no way to push the nil fee. It causes to deselect the `selected fee`
    func customFeeDidChanged(_ customFee: BSDKFee)
}

protocol SendCustomFeeService: CustomFeeProvider {
    func setup(input: CustomFeeServiceInput)
}
