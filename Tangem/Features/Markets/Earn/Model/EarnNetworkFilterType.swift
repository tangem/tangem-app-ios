//
//  EarnNetworkFilterType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

enum EarnNetworkFilterType: Hashable {
    case all
    case userNetworks(networkInfos: [EarnNetworkInfo])
    case specific(networkInfo: EarnNetworkInfo)

    var displayTitle: String {
        switch self {
        case .all:
            return Localization.earnFilterAllNetworks
        case .userNetworks:
            return Localization.earnFilterMyNetworks
        case .specific(let networkItem):
            return networkItem.networkName
        }
    }
}
