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

        switch tokenItem.blockchain {
        case .ethereum:
            return EthereumSelectorReceiveAssetsSectionFactory(input)
        case .bitcoin:
            return BitcoinSelectorReceiveAssetsSectionFactory(input)
        default:
            return CommonSelectorReceiveAssetsSectionFactory(input)
        }
    }
}
