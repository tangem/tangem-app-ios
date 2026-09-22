//
//  TangemPayTransactionDeeplink.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// The transaction a payment push reports. It answers to no host and no path: `TangemPayPushParser` is the only
/// thing that builds it, and the payload it carries is enough to show the transaction without asking anyone.
struct TangemPayTransactionDeeplink: Equatable {
    let payload: TangemPayPushPayload

    var action: DeeplinkNavigationAction { .tangemPayTransaction(self) }
}
