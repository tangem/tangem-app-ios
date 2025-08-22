//
//  AvailabilityReceiveFlowFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct AvailabilityReceiveFlowFactory {
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

    // MARK: Implementation

    func makeAvailabilityReceiveFlow() -> AvailabilityViewModel {
        if FeatureProvider.isAvailable(.receiveENS) {
            let options = ReceiveMainViewModel.Options(
                tokenItem: tokenItem,
                flow: flow,
                addressTypesProvider: addressTypesProvider
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
            addressInfos: addressTypesProvider.receiveAddressInfos
        )
    }

    // MARK: - Private Implementation

    /// Legacy flow. Remove when ReceiveBottomSheet did removed.
    private func makeDependenciesBuilder() -> ReceiveDependenciesBuilder {
        ReceiveDependenciesBuilder(
            flow: flow,
            tokenItem: tokenItem,
            addressTypesProvider: addressTypesProvider
        )
    }
}

extension AvailabilityReceiveFlowFactory {
    enum AvailabilityViewModel {
        case domainReceiveFlow(ReceiveMainViewModel)
        case bottomSheetReceiveFlow(ReceiveBottomSheetViewModel)
    }
}
