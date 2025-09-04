//
//  EthereumSelectorReceiveAssetsSectionFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct EthereumSelectorReceiveAssetsSectionFactory: SelectorReceiveAssetsSectionFactory {
    let analyticsLogger: ReceiveAnalyticsLogger

    // MARK: - Private Properties

    private let tokenItem: TokenItem
    private let coordinator: SelectorReceiveAssetItemRoutable?

    // MARK: - Init

    init(_ input: SelectorReceiveAssetsSectionFactoryInput) {
        tokenItem = input.tokenItem
        analyticsLogger = input.analyticsLogger
        coordinator = input.coordinator
    }

    // MARK: - Implementation

    func makeSections(from assets: [ReceiveAddressType]) -> [SelectorReceiveAssetsSection] {
        var domainAssets: [SelectorReceiveAssetsContentItemViewModel] = []
        var defaultAssets: [SelectorReceiveAssetsContentItemViewModel] = []

        for asset in assets {
            let stateView = makeStateViewModel(asset: asset, tokenItem: tokenItem, coordinator: coordinator)
            let viewModel = SelectorReceiveAssetsContentItemViewModel(stateView: stateView)

            switch asset {
            case .domain:
                domainAssets.append(viewModel)
            case .address:
                defaultAssets.append(viewModel)
            }
        }

        return [
            (id: SelectorReceiveAssetsSection.Key.domain, items: domainAssets),
            (id: SelectorReceiveAssetsSection.Key.default, items: defaultAssets),
        ]
        .compactMap { section in
            section.items.isEmpty ? nil : SelectorReceiveAssetsSection(
                id: section.id,
                header: nil,
                items: section.items
            )
        }
    }
}
