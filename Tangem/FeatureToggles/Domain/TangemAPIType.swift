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

    /// `apiBaseUrl` carrying the `/api` gateway segment documented in the Notification Preferences
    /// contract v1.3 (`/api/v1/...`). Kept separate from `apiBaseUrl` because only the
    /// notification-preferences endpoint uses it; the rest of the v1 API does not.
    public var apiBaseUrlWithGatewaySegment: URL {
        insertingApiSegment(into: apiBaseUrl)
    }

    /// `apiBaseUrlv2` carrying the `/api` gateway segment (`/api/v2/...`). Only the v2 `/tokens`
    /// endpoint from the Notification Preferences contract v1.3 uses it.
    public var apiBaseUrlv2WithGatewaySegment: URL {
        insertingApiSegment(into: apiBaseUrlv2)
    }

    /// Prepends the `/api` gateway segment to a base URL's path (`https://host/v1` ->
    /// `https://host/api/v1`). Documented in Notification Preferences contract v1.3.
    private func insertingApiSegment(into url: URL) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }

        components.path = "/api" + components.path
        return components.url ?? url
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
