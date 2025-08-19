//
//  ReceiveDependeciesBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct ReceiveDependenciesBuilder {
    private let flow: ReceiveFlow
    private let tokenItem: TokenItem
    private let addressInfos: [ReceiveAddressInfo]
    private let coordinator: SelectorReceiveAssetItemRoutable?

    // MARK: - Init

    init(
        flow: ReceiveFlow,
        tokenItem: TokenItem,
        addressInfos: [ReceiveAddressInfo],
        coordinator: SelectorReceiveAssetItemRoutable?
    ) {
        self.flow = flow
        self.tokenItem = tokenItem
        self.addressInfos = addressInfos
        self.coordinator = coordinator
    }

    // MARK: - Builder

    func makeSelectorReceiveAssetsSectionFactory() -> SelectorReceiveAssetsSectionFactory {
        switch tokenItem.blockchain {
        case .ethereum:
            EthereumSelectorReceiveAssetsSectionFactory(tokenItem: tokenItem, coordinator: coordinator)
        default:
            CommonSelectorReceiveAssetsSectionFactory(tokenItem: tokenItem, coordinator: coordinator)
        }
    }

    func makeSelectorReceiveAssetsInteractor() -> SelectorReceiveAssetsInteractor {
        let notificationInputsFactory = ReceiveBottomSheetNotificationInputsFactory(flow: flow)
        let notificationInputs = notificationInputsFactory.makeNotificationInputs(for: tokenItem)

        return CommonSelectorReceiveAssetsInteractor(
            addressInfos: addressInfos,
            notificationInputs: notificationInputs
        )
    }

    func makeReceiveBottomSheetNotificationInputsFactory() -> ReceiveBottomSheetNotificationInputsFactory {
        ReceiveBottomSheetNotificationInputsFactory(flow: flow)
    }
}
