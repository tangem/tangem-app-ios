//
//  IncomingActionHandlerSpy.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
@testable import Tangem

final class IncomingActionHandlerSpy: IncomingActionHandler {
    private let state = OSAllocatedUnfairLock(initialState: [URL]())

    var handledURLs: [URL] { state.withLock { $0 } }

    func handleIncomingURL(_ url: URL) -> Bool {
        state.withLock { $0.append(url) }
        return true
    }

    func handleIntent(_ intent: String) -> Bool {
        false
    }
}
