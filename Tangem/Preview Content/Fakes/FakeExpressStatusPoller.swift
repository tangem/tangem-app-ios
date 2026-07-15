//
//  FakeExpressStatusPoller.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress

final class FakeExpressStatusPoller<Iteration>: ExpressStatusPolling {
    func subscribe(_ handler: @escaping (Iteration) -> Void) -> Cancellable {
        AnyCancellable {}
    }
}
