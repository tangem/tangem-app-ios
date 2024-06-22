//
//  SendFeeInteractor.swift
//  Tangem
//
//  Created by Sergey Balashov on 18.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

protocol SendFeeInteractor {
    func update(selectedFee: SendFee)
    func updateFees()

    func feesPublisher() -> AnyPublisher<[SendFee], Never>
    func selectedFeePublisher() -> AnyPublisher<SendFee?, Never>

    func customFeeInputFieldModels() -> [SendCustomFeeInputFieldModel]

    func setup(input: SendFeeInput, output: SendFeeOutput)
}
