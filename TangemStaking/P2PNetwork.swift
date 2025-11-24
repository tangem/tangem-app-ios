//
//  P2PNetwork.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum P2PNetwork: String {
    case mainnet
    case hoodi

    public var apiBaseUrl: URL {
        switch self {
        case .mainnet:
            return URL(string: "https://api.p2p.org/".appending(path))!
        case .hoodi:
            return URL(string: "https://api-test.p2p.org/".appending(path))!
        }
    }

    private var path: String {
        "api/v1/staking/pool/\(rawValue)"
    }
}
