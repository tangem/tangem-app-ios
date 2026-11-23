//
//  BackendAuthenticationAPIType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.URL
import enum TangemNetworkUtils.WireMockEnvironment

enum BackendAuthenticationAPIType: String, CaseIterable {
    case production
    case development
    case mock

    var baseURL: URL {
        switch self {
        case .production:
            return URL(string: "https://api.tangem.org")!
        case .development:
            return URL(string: "https://api.tests-d.com")!
        case .mock:
            return URL(string: WireMockEnvironment.baseURL)!
        }
    }
}
