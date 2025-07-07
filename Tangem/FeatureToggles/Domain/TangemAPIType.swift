//
//  TangemAPIType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

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
            return URL(string: "https://wiremock.tests-d.com/v1")!
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

    public var tangemComBaseUrl: URL {
        switch self {
        case .prod:
            return URL(string: "https://tangem.com")!
        case .dev, .stage, .mock:
            return URL(string: "https://devweb.tangem.com")!
        }
    }
}
