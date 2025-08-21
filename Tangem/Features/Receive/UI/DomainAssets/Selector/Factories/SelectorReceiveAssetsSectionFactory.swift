//
//  SelectorReceiveAssetsSectionFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol SelectorReceiveAssetsSectionFactory {
    func makeSections(from assets: [ReceiveAsset]) -> [SelectorReceiveAssetsSection]
}

extension SelectorReceiveAssetsSectionFactory {
    func makeStateViewModel(asset: ReceiveAsset, tokenItem: TokenItem, coordinator: SelectorReceiveAssetItemRoutable?) -> SelectorReceiveAssetsContentItemViewModel.StateView {
        switch asset {
        case .address(let addressInfo):
            let viewModel = SelectorReceiveAssetsAddressItemViewModel(
                tokenItem: tokenItem,
                addressInfo: addressInfo,
                coordinator: coordinator
            )
            return .address(viewModel)
        case .domain(let domainName, let addressInfo):
            let viewModel = SelectorReceiveAssetsDomainItemViewModel(
                domainName: domainName,
                addressInfo: addressInfo,
                coordinator: coordinator
            )
            return .domain(viewModel)
        }
    }
}
