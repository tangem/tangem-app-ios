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
    var sourceToken: LoadingResult<SendSourceToken, any Error> { get }
    var sourceTokenPublisher: AnyPublisher<LoadingResult<SendSourceToken, any Error>, Never> { get }
}

/// Will be useful for swap
protocol SendSourceTokenOutput: AnyObject {
    func userDidSelect(sourceToken: SendSourceToken)
}
