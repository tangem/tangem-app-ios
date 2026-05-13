//
//  VisaAPIType.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

public enum VisaAPIType: String, CaseIterable, Codable {
    case prod
    case dev
    case mock

    public var isTestnet: Bool {
        switch self {
        case .prod:
            false
        case .dev, .mock:
            true
        }
    }

    public var baseURL: URL {
        switch self {
        case .dev:
            URL(string: "https://api.dev.us.paera.com")!
        case .prod:
            URL(string: "https://api.us.paera.com")!
        case .mock:
            #if DEBUG
            URL(string: WireMockEnvironment.baseURL)!
            #else
            URL(string: "https://api.us.paera.com")!
            #endif
        }
    }

    public var bffBaseURL: URL {
        baseURL
            .appendingPathComponent("bff-v2")
            .appendingPathComponent("v1")
    }
}
