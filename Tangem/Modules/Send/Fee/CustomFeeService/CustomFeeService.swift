//
//  CustomFeeService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol CustomFeeService: AnyObject {
    var customFeePublisher: AnyPublisher<Fee?, Never> { get }
    func setInput(_ input: SendModel)
    func setFee(_ fee: Fee)
    func didChangeCustomFee(_ value: Fee?)
    func models() -> [SendCustomFeeInputFieldModel]
}
