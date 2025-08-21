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

    // MARK: - Init

    init(
        flow: ReceiveFlow,
        tokenItem: TokenItem,
        addressTypesProvider: ReceiveAddressTypesProvider,
        coordinator: ReceiveFlowCoordinator?
    ) {
        self.flow = flow
        self.tokenItem = tokenItem
        self.addressTypesProvider = addressTypesProvider
        self.coordinator = coordinator
    }

    // MARK: Implementation

    func makeSelectorReceiveAssetViewModel() -> SelectorReceiveAssetsViewModel {
        let dependencies = makeDependenciesBuilder()
        let interactor = dependencies.makeSelectorReceiveAssetsInteractor()
        let sectionFactory = dependencies.makeSelectorReceiveAssetsSectionFactory(with: coordinator)

        return SelectorReceiveAssetsViewModel(interactor: interactor, sectionFactory: sectionFactory)
    }

    func makeTokenAlertReceiveAssetViewModel() -> TokenAlertReceiveAssetsViewModel {
        let selectorViewModel = makeSelectorReceiveAssetViewModel()

        return TokenAlertReceiveAssetsViewModel(
            tokenItem: tokenItem,
            selectorViewModel: selectorViewModel,
            coordinator: coordinator
        )
    }

    func makeQRCodeReceiveAssetViewModel(with addressInfo: ReceiveAddressInfo) -> QRCodeReceiveAssetsViewModel {
        QRCodeReceiveAssetsViewModel(
            flow: flow,
            tokenItem: tokenItem,
            addressInfo: addressInfo,
            coordinator: coordinator
        )
    }

    // MARK: - Private Implementation

    private func makeDependenciesBuilder() -> ReceiveDependenciesBuilder {
        ReceiveDependenciesBuilder(
            flow: flow,
            tokenItem: tokenItem,
            addressTypesProvider: addressTypesProvider
        )
    }
}

extension ReceiveFlowFactory {
    enum AvailabilityViewModel {
        case domainReceiveFlow(ReceiveMainViewModel)
        case bottomSheetReceiveFlow(ReceiveBottomSheetViewModel)
    }
}
