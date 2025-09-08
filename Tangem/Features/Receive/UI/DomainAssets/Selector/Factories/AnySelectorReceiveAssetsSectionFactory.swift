//
//  BitcoinSelectorReceiveAssetsSectionFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

struct AnySelectorReceiveAssetsSectionFactory: SelectorReceiveAssetsSectionFactory {
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
        var defaultAssets: [SelectorReceiveAssetsContentItemViewModel] = []
        var legacyAssets: [SelectorReceiveAssetsContentItemViewModel] = []

        for asset in assets {
            let stateView = makeStateViewModel(asset: asset, tokenItem: tokenItem, coordinator: coordinator)
            let viewModel = SelectorReceiveAssetsContentItemViewModel(stateView: stateView)

            switch asset.info.type {
            case .default:
                defaultAssets.append(viewModel)
            case .legacy:
                legacyAssets.append(viewModel)
            }
        }

        let sections = [
            (id: SelectorReceiveAssetsSection.Key.default, items: defaultAssets),
            (id: SelectorReceiveAssetsSection.Key.legacy, items: legacyAssets),
        ]

        return sections.compactMap { section in
            section.items.isEmpty ? nil : SelectorReceiveAssetsSection(
                id: section.id,
                header: makeHeader(by: section.id),
                items: section.items
            )
        }
    }

    func makeTitleItemStateView(tokenItem: TokenItem, addressInfo: ReceiveAddressInfo) -> String {
        switch addressInfo.type {
        case .default:
            Localization.domainReceiveAssetsDefaultAddress
        case .legacy:
            Localization.domainReceiveAssetsLegacyAddress
        }
    }

    // MARK: - Private Implementation

    // [REDACTED_TODO_COMMENT]
    private func makeHeader(by key: SelectorReceiveAssetsSection.Key) -> SelectorReceiveAssetsSection.Header? {
        switch key {
        case .default, .legacy, .domain:
            return nil
        }
    }
}
