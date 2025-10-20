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
        case .ethereum:
            return Localization.domainReceiveAssetsNetworkNameAddress(tokenItem.name.capitalizingFirstLetter())
        default:
            return anySelectorBuildTitle(addressType: addressType)
        }
    }

    // MARK: - Private Implementation

    func anySelectorBuildTitle(addressType: AddressType) -> String {
        switch addressType {
        case .default:
            Localization.domainReceiveAssetsDefaultAddress
        case .legacy:
            Localization.domainReceiveAssetsLegacyAddress
        }
    }
}
