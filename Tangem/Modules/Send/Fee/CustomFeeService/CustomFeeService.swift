//
//  CustomFeeService.swift
//  Tangem
//
//  Created by Andrey Chukavin on 01.04.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

protocol CustomFeeService: AnyObject {
    func initialSetupCustomFee(_ fee: Fee)
    func inputFieldModels() -> [SendCustomFeeInputFieldModel]
}

protocol CustomFeeServiceInput: AnyObject {
    var cryptoAmountPublisher: AnyPublisher<Amount, Never> { get }
    var destinationPublisher: AnyPublisher<String, Never> { get }
}

protocol CustomFeeServiceOutput: AnyObject {
    func customFeeDidChanged(_ customFee: Fee?)
}
