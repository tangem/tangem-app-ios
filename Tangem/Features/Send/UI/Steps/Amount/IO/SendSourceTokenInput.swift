//
//  SendSourceTokenInput.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

protocol SendSourceTokenInput: AnyObject {
    var sourceToken: SendSourceToken { get }
    var sourceTokenPublisher: AnyPublisher<SendSourceToken, Never> { get }
}

/// Will be useful for swap
protocol SendSourceTokenOutput: AnyObject {
    func userDidSelect(sourceToken: SendSourceToken)
}
