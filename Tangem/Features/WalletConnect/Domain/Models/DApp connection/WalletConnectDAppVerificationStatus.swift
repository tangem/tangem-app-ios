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
    case malicious([AttackType])

    var isVerified: Bool {
        switch self {
        case .verified:
            true
        case .unknownDomain, .malicious:
            false
        }
    }
}

extension WalletConnectDAppVerificationStatus {
    enum AttackType: Equatable {
        case signatureFarming
        case approvalFarming
        case setApprovalForAll
        case transferFarming
        case rawEtherTransfer
        case seaportFarming
        case blurFarming
        case permitFarming
        case other
    }
}
