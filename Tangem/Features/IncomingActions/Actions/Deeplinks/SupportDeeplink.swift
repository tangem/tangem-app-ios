//
//  SupportDeeplink.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// `tangem://support`
///
/// The chat is one conversation per device, so there is nothing for the link to name: neither the wallet nor
/// a message of its own. Whatever it happens to carry is read by nobody.
struct SupportDeeplink: HostNamedDeeplink, Equatable {
    static let host = "support"

    var action: DeeplinkNavigationAction { .support(self) }
}

// MARK: - Parsing

extension SupportDeeplink {
    init(link _: DeeplinkURL) {}
}
