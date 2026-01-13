//
//  TangemPayAPIType.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum TangemPayAPIType: String, CaseIterable, Codable {
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

    public var baseURL: URL {
        switch self {
        case .dev:
            URL(string: "https://api.dev.us.paera.com")!
        case .prod:
            URL(string: "https://api.us.paera.com")!
        }
    }

    public var bffBaseURL: URL {
        baseURL
            .appendingPathComponent("bff-v2")
            .appendingPathComponent("v1")
    }
}
