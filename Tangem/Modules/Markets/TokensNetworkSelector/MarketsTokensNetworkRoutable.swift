//
//  MarketsTokensNetworkRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol MarketsTokensNetworkRoutable: AnyObject {
    func openWalletSelector(with provider: MarketsWalletDataProvider)
    func dissmis()
}
