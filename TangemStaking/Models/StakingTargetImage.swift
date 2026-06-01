//
//  StakingTargetImage.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum StakingTargetImage: Hashable {
    case url(URL)
    case local(StakingLocalImageType)
}

public enum StakingLocalImageType: Hashable {
    case p2pVault
}
