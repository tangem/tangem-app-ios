//
//  BlockaidSiteScanResult.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct BlockaidSiteScanResult {
    let isMalicious: Bool?
    let attackTypes: [AttackType]

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
