//
//  P2PNetwork.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

public enum P2PNetwork: String {
    case mainnet
    case hoodi
    case mock

    public var apiBaseUrl: URL {
        switch self {
        case .mainnet:
            return URL(string: "https://api.p2p.org/".appending(path))!
        case .hoodi:
            return URL(string: "https://api-test.p2p.org/".appending(path))!
        case .mock:
            return URL(string: "\(WireMockEnvironment.baseURL)/p2p_api/".appending(path))!
        }
    }

    private var path: String {
        switch self {
        case .mainnet, .mock:
            return "api/v1/staking/pool/mainnet"
        case .hoodi:
            return "api/v1/staking/pool/hoodi"
        }
    }
}
