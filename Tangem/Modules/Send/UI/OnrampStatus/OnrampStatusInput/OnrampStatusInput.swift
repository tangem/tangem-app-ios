//
//  OnrampStatusInput.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine

protocol OnrampStatusInput: AnyObject {
    var expressTransactionId: AnyPublisher<String, Never> { get }
}
