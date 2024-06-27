//
//  CustomFeeServiceInputOutput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine

protocol CustomFeeServiceInput: AnyObject {
    var customFee: Fee? { get }
    var cryptoAmountPublisher: AnyPublisher<Amount?, Never> { get }
    var destinationAddressPublisher: AnyPublisher<String?, Never> { get }
    var feeValuePublisher: AnyPublisher<BlockchainSdk.Fee?, Never> { get }
}

protocol CustomFeeServiceOutput: AnyObject {
    func setCustomFee(_ customFee: Fee?)
}
