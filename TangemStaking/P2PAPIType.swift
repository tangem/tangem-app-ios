//
//  P2PAPIType.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum P2PAPIType: String, CaseIterable, Codable {
    case prod
    case dev

    public var apiBaseUrl: URL {
        switch self {
        case .prod:
            return URL(string: "https://api.p2p.org")!
        case .dev:
            return URL(string: "https://api-test.p2p.org/")!
        }
    }
}
