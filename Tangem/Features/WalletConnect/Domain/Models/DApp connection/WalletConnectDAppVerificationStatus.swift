//
//  WalletConnectDAppVerificationStatus.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum WalletConnectDAppVerificationStatus: Equatable {
    case verified
    case unknownDomain
    case malicious

    var isVerified: Bool {
        switch self {
        case .verified:
            true
        case .unknownDomain, .malicious:
            false
        }
    }
}
