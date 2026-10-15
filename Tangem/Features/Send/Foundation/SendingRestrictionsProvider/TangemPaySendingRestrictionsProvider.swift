//
//  TangemPaySendingRestrictionsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

struct TangemPaySendingRestrictionsProvider: SendingRestrictionsProvider {
    var sendingRestrictionsPublisher: AnyPublisher<SendingRestrictions?, Never> {
        // TangemPay doesn't have sending restrictions
        .just(output: nil)
    }
}
