//
//  ConciergeWaitlistLink.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum ConciergeWaitlistLink {
    private static let scheme = "tangem"
    private static let host = "onramp"
    private static let type = "concierge_waitlist"

    private enum Keys {
        static let type = "type"
    }

    static func matches(_ url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme?.lowercased() == scheme,
              components.host?.lowercased() == host else {
            return false
        }

        return components.queryItems?.first { $0.name == Keys.type }?.value?.lowercased() == type
    }
}
