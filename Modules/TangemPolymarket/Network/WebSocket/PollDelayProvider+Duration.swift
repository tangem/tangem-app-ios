//
//  PollDelayProvider+Duration.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

extension PollDelayProvider {
    func waitUnlessCancelled(_ duration: Duration) async -> Bool {
        do {
            try await wait(for: duration / .seconds(1))
            return !Task.isCancelled
        } catch {
            return false
        }
    }
}
