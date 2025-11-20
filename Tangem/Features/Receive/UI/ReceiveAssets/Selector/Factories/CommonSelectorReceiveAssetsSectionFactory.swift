//
//  CommonSelectorReceiveAssetsSectionFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct CommonSelectorReceiveAssetsSectionFactory: SelectorReceiveAssetsSectionFactory {
    let analyticsLogger: any ReceiveAnalyticsLogger

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
        [
            makeDomainSection(for: assets),
            makeAddressSection(for: assets),
        ]
    }

    // MARK: - Private Implementation

    private func makeDomainSection(for assets: [ReceiveAddressType]) -> SelectorReceiveAssetsSection {
        let domainItems: [SelectorReceiveAssetsDomainItemViewModel] = assets
            .filter { $0.key == .domain }
            .compactMap {
                let viewModel = SelectorReceiveAssetsDomainItemViewModel(
                    domainName: $0.domainName ?? "",
                    addressInfo: $0.info,
                    analyticsLogger: analyticsLogger,
                    coordinator: coordinator
                )
                return viewModel
            }

        return SelectorReceiveAssetsSection(
            id: .domain,
            items: [
                SelectorReceiveAssetsContentItemViewModel(viewState: .domain(domainItems)),
            ]
        )
    }

    private func makeAddressSection(for assets: [ReceiveAddressType]) -> SelectorReceiveAssetsSection {
        let addressItems: [SelectorReceiveAssetsAddressPageItemViewModel] = assets
            .filter { $0.key == .address }
            .compactMap {
                let viewModel = SelectorReceiveAssetsAddressPageItemViewModel(
                    tokenItem: tokenItem,
                    addressInfo: $0.info,
                    analyticsLogger: analyticsLogger,
                    coordinator: coordinator
                )
                return viewModel
            }

        return SelectorReceiveAssetsSection(
            id: .default,
            items: [
                SelectorReceiveAssetsContentItemViewModel(viewState: .address(addressItems)),
            ]
        )
    }
}
