//
//  CollectiblesAccountSendingRestrictionsProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

struct CollectiblesAccountSendingRestrictionsProvider: SendingRestrictionsProvider {
    var sendingRestrictionsPublisher: AnyPublisher<SendingRestrictions?, Never> {
        .just(output: nil)
    }
}
