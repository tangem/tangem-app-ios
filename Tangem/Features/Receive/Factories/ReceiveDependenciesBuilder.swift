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
    // [REDACTED_TODO_COMMENT]
    private let yieldModuleData: Bool?

    // MARK: - Init

    init(
        flow: ReceiveFlow,
        tokenItem: TokenItem,
        addressTypesProvider: ReceiveAddressTypesProvider,
        yieldModuleData: Bool? = nil // WIP - This will be a Yield Module service with a state inside
    ) {
        self.flow = flow
        self.tokenItem = tokenItem
        self.addressTypesProvider = addressTypesProvider
        self.yieldModuleData = yieldModuleData
    }

    // MARK: - Builder

    func makeSelectorReceiveAssetsInteractor() -> SelectorReceiveAssetsInteractor {
        let notificationInputsFactory = ReceiveBottomSheetNotificationInputsFactory(flow: flow, yieldModuleData: yieldModuleData)
        let notificationInputs = notificationInputsFactory.makeNotificationInputs(for: tokenItem)

        return CommonSelectorReceiveAssetsInteractor(
            notificationInputs: notificationInputs,
            addressTypes: addressTypesProvider.receiveAddressTypes
        )
    }

    func makeReceiveBottomSheetNotificationInputsFactory() -> ReceiveBottomSheetNotificationInputsFactory {
        ReceiveBottomSheetNotificationInputsFactory(flow: flow, yieldModuleData: yieldModuleData)
    }

    func makeAnalyticsLogger() -> ReceiveAnalyticsLogger {
        CommonReceiveAnalyticsLogger(flow: flow, tokenItem: tokenItem)
    }

    func makeSelectorReceiveAssetsSectionFactory(with coordinator: SelectorReceiveAssetItemRoutable?) -> SelectorReceiveAssetsSectionFactory {
        let analyticsLogger = makeAnalyticsLogger()

        let input = SelectorReceiveAssetsSectionFactoryInput(
            tokenItem: tokenItem,
            analyticsLogger: analyticsLogger,
            coordinator: coordinator
        )

        let hasLegacyAssets = addressTypesProvider.receiveAddressInfos
            .contains(where: { $0.type == .legacy })

        switch tokenItem.blockchain {
        case .ethereum:
            return EthereumSelectorReceiveAssetsSectionFactory(input)
        default:
            return hasLegacyAssets ? AnySelectorReceiveAssetsSectionFactory(input) : CommonSelectorReceiveAssetsSectionFactory(input)
        }
    }
}
