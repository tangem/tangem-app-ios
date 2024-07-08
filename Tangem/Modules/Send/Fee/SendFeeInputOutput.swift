//
//  SendFeeInputOutput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import struct BlockchainSdk.Amount

protocol SendFeeInput: AnyObject {
    var selectedFee: SendFee? { get }
    var selectedFeePublisher: AnyPublisher<SendFee?, Never> { get }
    var cryptoAmountPublisher: AnyPublisher<Amount, Never> { get }
    var destinationAddressPublisher: AnyPublisher<String?, Never> { get }
}

protocol SendFeeOutput: AnyObject {
    func feeDidChanged(fee: SendFee)
}
