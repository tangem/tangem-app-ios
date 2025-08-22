//
//  ReceiveDependeciesBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct ReceiveDependenciesBuilder {
    private let flow: ReceiveFlow
    private let tokenItem: TokenItem
    private let addressTypesProvider: ReceiveAddressTypesProvider

    // MARK: - Init

    init(
        flow: ReceiveFlow,
        tokenItem: TokenItem,
        addressTypesProvider: ReceiveAddressTypesProvider
    ) {
        self.flow = flow
        self.tokenItem = tokenItem
        self.addressTypesProvider = addressTypesProvider
    }

    // MARK: - Builder

    func makeSelectorReceiveAssetsSectionFactory(with coordinator: SelectorReceiveAssetItemRoutable?) -> SelectorReceiveAssetsSectionFactory {
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
            notificationInputs: notificationInputs,
            addressTypes: addressTypesProvider.receiveAddressTypes
        )
    }

    func makeReceiveBottomSheetNotificationInputsFactory() -> ReceiveBottomSheetNotificationInputsFactory {
        ReceiveBottomSheetNotificationInputsFactory(flow: flow)
    }
}
