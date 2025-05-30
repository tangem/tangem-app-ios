//
//  SendAmountModifier.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol SendAmountModifier {
    var modifyingMessagePublisher: AnyPublisher<String?, Never> { get }

    func modify(cryptoAmount: Decimal?) -> Decimal?
}
