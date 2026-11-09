//
//  PolymarketPollingDoubles.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
@testable import Tangem

final class AppStateObserverStub: AppStateObserving {
    private var onChange: (@MainActor (Bool) -> Void)?

    func start(onChange: @escaping @MainActor (_ isInBackground: Bool) -> Void) {
        self.onChange = onChange
    }

    @MainActor
    func enterBackground() {
        onChange?(true)
    }

    @MainActor
    func enterForeground() {
        onChange?(false)
    }
}
