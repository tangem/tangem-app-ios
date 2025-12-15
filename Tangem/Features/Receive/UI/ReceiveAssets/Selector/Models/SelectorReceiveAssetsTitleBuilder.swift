//
//  SelectorReceiveAssetsTitleBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemLocalization

struct SelectorReceiveAssetsTitleBuilder {
    func build(for tokenItem: TokenItem, with addressType: AddressType) -> String {
        switch tokenItem.blockchain {
        case .bitcoin where addressType == .legacy:
            return Localization.domainReceiveAssetsLegacyAddress(tokenItem.name.capitalizingFirstLetter())
        default:
            return Localization.domainReceiveAssetsNetworkNameAddress(tokenItem.name.capitalizingFirstLetter())
        }
    }
}
