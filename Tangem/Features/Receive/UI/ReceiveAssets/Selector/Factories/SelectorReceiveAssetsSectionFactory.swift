//
//  SelectorReceiveAssetsSectionFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

protocol SelectorReceiveAssetsSectionFactory {
    var analyticsLogger: ReceiveAnalyticsLogger { get }

    func makeSections(from assets: [ReceiveAddressType]) -> [SelectorReceiveAssetsSection]
}

struct SelectorReceiveAssetsSectionFactoryInput {
    let tokenItem: TokenItem
    let analyticsLogger: ReceiveAnalyticsLogger
    let coordinator: SelectorReceiveAssetItemRoutable?
}
