//
//  ReceiveFlowFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct ReceiveFlowFactory {
    private let flow: ReceiveFlow
    private let tokenItem: TokenItem
    private let addressTypesProvider: ReceiveAddressTypesProvider
    private let coordinator: ReceiveFlowCoordinator?
    // [REDACTED_TODO_COMMENT]
    private let isYieldModuleActive: Bool

    // MARK: - Init

    init(
        flow: ReceiveFlow,
        tokenItem: TokenItem,
        addressTypesProvider: ReceiveAddressTypesProvider,
        coordinator: ReceiveFlowCoordinator?,
        // [REDACTED_TODO_COMMENT]
        isYieldModuleActive: Bool = false
    ) {
        self.flow = flow
        self.tokenItem = tokenItem
        self.addressTypesProvider = addressTypesProvider
        self.coordinator = coordinator
        self.isYieldModuleActive = isYieldModuleActive
    }

    // MARK: Implementation

    func makeSelectorReceiveAssetViewModel() -> SelectorReceiveAssetsViewModel {
        let dependencies = makeDependenciesBuilder()
        let interactor = dependencies.makeSelectorReceiveAssetsInteractor()
        let sectionFactory = dependencies.makeSelectorReceiveAssetsSectionFactory(with: coordinator)
        let analyticsLogger = dependencies.makeAnalyticsLogger()

        return SelectorReceiveAssetsViewModel(
            interactor: interactor,
            analyticsLogger: analyticsLogger,
            sectionFactory: sectionFactory
        )
    }

    func makeTokenAlertReceiveAssetViewModel(with selectorViewModel: SelectorReceiveAssetsViewModel) -> TokenAlertReceiveAssetsViewModel {
        return TokenAlertReceiveAssetsViewModel(
            tokenItem: tokenItem,
            selectorViewModel: selectorViewModel,
            coordinator: coordinator
        )
    }

    func makeQRCodeReceiveAssetViewModel(with addressInfo: ReceiveAddressInfo) -> QRCodeReceiveAssetsViewModel {
        let dependencies = makeDependenciesBuilder()
        let analyticsLogger = dependencies.makeAnalyticsLogger()

        return QRCodeReceiveAssetsViewModel(
            flow: flow,
            tokenItem: tokenItem,
            addressInfo: addressInfo,
            analyticsLogger: analyticsLogger,
            coordinator: coordinator
        )
    }

    // MARK: - Private Implementation

    private func makeDependenciesBuilder() -> ReceiveDependenciesBuilder {
        ReceiveDependenciesBuilder(
            flow: flow,
            tokenItem: tokenItem,
            addressTypesProvider: addressTypesProvider,
            // [REDACTED_TODO_COMMENT]
            isYieldModuleActive: isYieldModuleActive
        )
    }
}
