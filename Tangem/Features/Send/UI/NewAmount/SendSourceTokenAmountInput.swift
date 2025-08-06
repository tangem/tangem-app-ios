//
//  SendSourceTokenAmountInput.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation
import Combine

protocol SendSourceTokenAmountInput: AnyObject {
    var sourceAmount: LoadingResult<SendAmount, any Error> { get }
    var sourceAmountPublisher: AnyPublisher<LoadingResult<SendAmount, Error>, Never> { get }
}

protocol SendSourceTokenAmountOutput: AnyObject {
    func sourceAmountDidChanged(amount: SendAmount?)
}
