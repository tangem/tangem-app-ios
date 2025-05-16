//
//  WalletConnectDAppVerificationStatus.swift
//  TangemApp
//
<<<<<<<< HEAD:Tangem/Features/WalletConnect/Domain/Models/DApp connection/WalletConnectDAppVerificationStatus.swift
//  Created by [REDACTED_AUTHOR]
========
//  Created by [REDACTED_AUTHOR]
>>>>>>>> 010e73131 ([REDACTED_INFO] DApp information fetch refactoring WIP.):Tangem/Features/WalletConnect/Domain/Models/WalletConnectDAppVerificationStatus.swift
//  Copyright © 2025 Tangem AG. All rights reserved.
//

enum WalletConnectDAppVerificationStatus {
    case verified
    case unknownDomain
    case malicious([AttackType])
}

extension WalletConnectDAppVerificationStatus {
    enum AttackType {
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
