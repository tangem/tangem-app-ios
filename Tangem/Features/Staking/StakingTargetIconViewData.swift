//
//  StakingTargetIconViewData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import TangemStaking

enum StakingTargetIconViewData: Hashable {
    case url(URL?)
    case asset(ImageType)
}

extension StakingTargetIconViewData {
    init(_ image: StakingTargetImage?) {
        switch image {
        case .url(let url): self = .url(url)
        case .local(.p2pVault): self = .asset(Assets.p2pLogo)
        case .none: self = .url(nil)
        }
    }
}
