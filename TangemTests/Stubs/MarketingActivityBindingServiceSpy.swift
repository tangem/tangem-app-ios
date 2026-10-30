//
//  MarketingActivityBindingServiceSpy.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation
@testable import Tangem

final class MarketingActivityBindingServiceSpy: MarketingActivityBindingService {
    private let state = OSAllocatedUnfairLock(initialState: [String]())

    var registeredUids: [String] {
        state.withLock { $0 }
    }

    func initialize() {}

    func register(uid: String) {
        state.withLock { $0.append(uid) }
    }
}
