//
//  TangemPayAwaitingDepositCanceller.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

protocol TangemPayAwaitingDepositCanceller {
    var awaitingDepositInfoPublisher: AnyPublisher<TangemPayAwaitingDepositInfo?, Never> { get }
    func cancelAwaitingDepositOrder() async throws
}
