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
    func makeTitleItemStateView(tokenItem: TokenItem, addressInfo: ReceiveAddressInfo) -> String
}

extension SelectorReceiveAssetsSectionFactory {
    func makeStateViewModel(asset: ReceiveAddressType, tokenItem: TokenItem, coordinator: SelectorReceiveAssetItemRoutable?) -> SelectorReceiveAssetsContentItemViewModel.StateView {
        switch asset {
        case .address(let addressInfo):
            let viewModel = SelectorReceiveAssetsAddressItemViewModel(
                title: makeTitleItemStateView(tokenItem: tokenItem, addressInfo: addressInfo),
                addressInfo: addressInfo,
                analyticsLogger: analyticsLogger,
                coordinator: coordinator
            )
            return .address(viewModel)
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

    func makeTitleItemStateView(tokenItem: TokenItem, addressInfo: ReceiveAddressInfo) -> String {
        Localization.domainReceiveAssetsNetworkNameAddress(tokenItem.name.capitalizingFirstLetter())
    }
}

struct SelectorReceiveAssetsSectionFactoryInput {
    let tokenItem: TokenItem
    let analyticsLogger: ReceiveAnalyticsLogger
    let coordinator: SelectorReceiveAssetItemRoutable?
}
