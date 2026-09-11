//
//  AwaitSettled.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Awaits a repeatedly restarted background job, re-reading the slot it is stored in: while a newer task
/// replaces the one being awaited, keeps waiting, so the caller observes the result built from the latest
/// inputs rather than the one it happened to see first. Callers keep the slot under a lock — the send flows
/// read it off the main thread while the inputs that restart the job change on it.
///
/// Returns once the caller is cancelled: the awaited job ignores that cancellation, so a superseded send
/// would otherwise sit here waiting for updates it no longer owns and then dispatch anyway. Callers check
/// cancellation themselves after the wait — this one only stops re-arming.
func awaitSettled(_ latestTask: () -> Task<Void, Never>?) async {
    while let awaited = latestTask() {
        await awaited.value

        if Task.isCancelled || latestTask() == awaited {
            return
        }
    }
}
