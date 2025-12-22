//
//  VisaAPIType.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum VisaAPIType: String, CaseIterable, Codable {
    case prod
    case dev

    public var isTestnet: Bool {
        switch self {
        case .prod:
            false
        case .dev:
            true
        }
    }

    var baseURL: URL {
        switch self {
        case .dev:
            URL(string: "https://api.dev.us.paera.com")!
        case .prod:
            URL(string: "https://api.us.paera.com")!
        }
    }

    var bffBaseURL: URL {
        baseURL
            .appendingPathComponent("bff-v2")
            .appendingPathComponent("v1")
    }
}
