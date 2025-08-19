//
//  CommonSelectorReceiveAssetsSectionFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct CommonSelectorReceiveAssetsSectionFactory: SelectorReceiveAssetsSectionFactory {
    // MARK: - Private Properties

    private let tokenItem: TokenItem
    private let coordinator: SelectorReceiveAssetItemRoutable?

    // MARK: - Init

    init(tokenItem: TokenItem, coordinator: SelectorReceiveAssetItemRoutable?) {
        self.tokenItem = tokenItem
        self.coordinator = coordinator
    }

    // MARK: - Implementation

    func makeSections(from assets: [ReceiveAsset]) -> [SelectorReceiveAssetsSection] {
        let assetItems: [SelectorReceiveAssetsContentItemViewModel] = assets.compactMap {
            let stateView = makeStateViewModel(asset: $0, tokenItem: tokenItem, coordinator: coordinator)
            return SelectorReceiveAssetsContentItemViewModel(stateView: stateView)
        }

        return [
            SelectorReceiveAssetsSection(
                id: .default,
                header: nil,
                items: assetItems
            ),
        ]
    }
}
