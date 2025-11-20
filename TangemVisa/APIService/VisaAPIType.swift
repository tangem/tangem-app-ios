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
    case stage
    case dev

    public var isTestnet: Bool {
        switch self {
        case .prod:
            return false
        case .stage, .dev:
            return true
        }
    }

    var baseURL: URL {
        switch self {
        case .dev:
            return .init(string: "https://api.dev.us.paera.com/bff/v1")!
        case .stage:
            // [REDACTED_TODO_COMMENT]
            return .init(string: "https://api.dev.us.paera.com/bff/v1")!
        case .prod:
            return .init(string: "https://api.us.paera.com/bff/v1")!
        }
    }
}
