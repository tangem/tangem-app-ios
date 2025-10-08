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

extension SelectorReceiveAssetsSectionFactory {
    func makeStateViewModel(asset: ReceiveAddressType, tokenItem: TokenItem, coordinator: SelectorReceiveAssetItemRoutable?) -> SelectorReceiveAssetsContentItemViewModel.StateView {
        switch asset {
        case .address(let addressInfo):
            let viewModel = SelectorReceiveAssetsAddressPageItemViewModel(
                tokenItem: tokenItem,
                addressInfo: addressInfo,
                analyticsLogger: analyticsLogger,
                coordinator: coordinator
            )
            return .address([viewModel])
        case .domain(let domainName, let addressInfo):
            let viewModel = SelectorReceiveAssetsDomainItemViewModel(
                domainName: domainName,
                addressInfo: addressInfo,
                analyticsLogger: analyticsLogger,
                coordinator: coordinator
            )
            return .domain(viewModel)
        }
    }
}

struct SelectorReceiveAssetsSectionFactoryInput {
    let tokenItem: TokenItem
    let analyticsLogger: ReceiveAnalyticsLogger
    let coordinator: SelectorReceiveAssetItemRoutable?
}
