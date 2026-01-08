//
//  CustomFeeService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

protocol CustomFeeService: AnyObject {
    func initialSetupCustomFee(_ fee: Fee)

    func setup(output: CustomFeeServiceOutput)
}

typealias CustomFeeServiceInput = SendFeeProviderInput

protocol CustomFeeServiceOutput: AnyObject {
    /// There is no way to push the nil fee. It causes to deselect the `selected fee`
    func customFeeDidChanged(_ customFee: Fee)
}

protocol SendCustomFeeService: FeeSelectorCustomFeeProvider {
    func setup(input: SendFeeProviderInput)
}
