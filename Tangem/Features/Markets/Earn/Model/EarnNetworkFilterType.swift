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
            Localization.earnFilterAllNetworks
        case .userNetworks:
            Localization.earnFilterMyNetworks
        case .specific(let networkItem):
            networkItem.networkName
        }
    }
}
