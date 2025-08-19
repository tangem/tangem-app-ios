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
    private let addressInfos: [ReceiveAddressInfo]
    private let coordinator: (TokenAlertReceiveAssetsRoutable & SelectorReceiveAssetItemRoutable)?

    // MARK: - Init

    init(
        flow: ReceiveFlow,
        tokenItem: TokenItem,
        addressInfos: [ReceiveAddressInfo],
        coordinator: (
            TokenAlertReceiveAssetsRoutable &
                SelectorReceiveAssetItemRoutable
        )? = nil
    ) {
        self.flow = flow
        self.tokenItem = tokenItem
        self.addressInfos = addressInfos
        self.coordinator = coordinator
    }

    // MARK: Implementation

    func makeAvailabilityReceiveFlow() -> AvailabilityViewModel {
        if FeatureProvider.isAvailable(.receiveENS), flow == .crypto {
            let options = ReceiveMainViewModel.Options(
                tokenItem: tokenItem,
                addressInfos: addressInfos,
                flow: flow
            )

            let receiveMainViewModel = ReceiveMainViewModel(options: options)
            receiveMainViewModel.start()

            return .domainReceiveFlow(receiveMainViewModel)
        } else {
            let receiveBottomSheetViewModel = makeBottomSheetViewModel()
            return .bottomSheetReceiveFlow(receiveBottomSheetViewModel)
        }
    }

    func makeBottomSheetViewModel() -> ReceiveBottomSheetViewModel {
        let dependencies = makeDependenciesBuilder()
        let receiveBottomSheetNotificationInputsFactory = dependencies.makeReceiveBottomSheetNotificationInputsFactory()
        let notificationInputs = receiveBottomSheetNotificationInputsFactory.makeNotificationInputs(for: tokenItem)

        return ReceiveBottomSheetViewModel(
            flow: flow,
            tokenItem: tokenItem,
            notificationInputs: notificationInputs,
            addressInfos: addressInfos
        )
    }

    func makeSelectorReceiveAssetViewModel() -> SelectorReceiveAssetsViewModel {
        let dependencies = makeDependenciesBuilder()
        let interactor = dependencies.makeSelectorReceiveAssetsInteractor()
        let sectionFactory = dependencies.makeSelectorReceiveAssetsSectionFactory()

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

    // [REDACTED_TODO_COMMENT]

    // MARK: - Private Implementation

    private func makeDependenciesBuilder() -> ReceiveDependenciesBuilder {
        ReceiveDependenciesBuilder(
            flow: flow,
            tokenItem: tokenItem,
            addressInfos: addressInfos,
            coordinator: coordinator
        )
    }
}

extension ReceiveFlowFactory {
    enum AvailabilityViewModel {
        case domainReceiveFlow(ReceiveMainViewModel)
        case bottomSheetReceiveFlow(ReceiveBottomSheetViewModel)
    }
}
