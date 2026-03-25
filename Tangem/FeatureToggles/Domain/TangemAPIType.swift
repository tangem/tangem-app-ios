//
//  TangemAPIType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

public enum TangemAPIType: String, CaseIterable, Codable {
    case prod
    case dev
    case stage
    case mock

    public var apiBaseUrl: URL {
        switch self {
        case .prod:
            return URL(string: "https://api.tangem.org/v1")!
        case .dev:
            return URL(string: "https://api.tests-d.com/v1")!
        case .stage:
            return URL(string: "https://api.tests-s.com/v1")!
        case .mock:
            return URL(string: "\(WireMockEnvironment.baseURL)/v1")!
        }
    }

    public var apiBaseUrlv2: URL {
        switch self {
        case .prod:
            return URL(string: "https://api.tangem.org/v2")!
        case .dev:
            return URL(string: "https://api.tests-d.com/v2")!
        case .stage:
            return URL(string: "https://api.tests-s.com/v2")!
        case .mock:
            return URL(string: "\(WireMockEnvironment.baseURL)/v2")!
        }
    }

    public var iconBaseUrl: URL {
        switch self {
        case .prod:
            return URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/")!
        case .dev, .stage, .mock:
            return URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api.dev/")!
        }
    }

    public var activatePromoCodeApiBaseUrl: URL {
        switch self {
        case .prod:
            return URL(string: "https://api.tangem.org/promo/v1")!
        case .dev:
            return URL(string: "https://api.tests-d.com/promo/v1")!
        case .stage:
            return URL(string: "https://api.tests-s.com/promo/v1")!
        case .mock:
            return URL(string: "\(WireMockEnvironment.baseURL)/promo/v1")!
        }
    }

    public var tangemComBaseUrl: URL {
        switch self {
        case .prod:
            return URL(string: "https://tangem.com")!
        case .dev, .stage, .mock:
            return URL(string: "https://devweb.tangem.com")!
        }
    }
}
