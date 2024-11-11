//
//  OnrampPaymentMethodsInputOutput.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress

protocol OnrampPaymentMethodsInput: AnyObject {
    var selectedOnrampPaymentMethod: OnrampPaymentMethod? { get }
    var selectedOnrampPaymentMethodPublisher: AnyPublisher<OnrampPaymentMethod?, Never> { get }
}

protocol OnrampPaymentMethodsOutput: AnyObject {
    func userDidSelect(paymentMethod: OnrampPaymentMethod)
}
