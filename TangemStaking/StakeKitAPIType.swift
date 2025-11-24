//
//  StakeKitAPIType.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum StakeKitAPIType: String, CaseIterable, Codable {
    case prod
    case mock

    public var apiBaseUrl: URL {
        switch self {
        case .prod:
            return URL(string: "https://api.stakek.it/v1/")!
        case .mock:
            return URL(string: "https://wiremock.tests-d.com/stake_api/v1/")!
        }
    }
}
