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
    // [REDACTED_TODO_COMMENT]
    private let isYieldModuleActive: Bool

    // MARK: - Init

    init(
        flow: ReceiveFlow,
        tokenItem: TokenItem,
        addressTypesProvider: ReceiveAddressTypesProvider,
        // [REDACTED_TODO_COMMENT]
        isYieldModuleActive: Bool = false
    ) {
        self.flow = flow
        self.tokenItem = tokenItem
        self.addressTypesProvider = addressTypesProvider
        self.isYieldModuleActive = isYieldModuleActive
    }

    // MARK: Implementation

    func makeAvailabilityReceiveFlow() -> AvailabilityViewModel {
        if FeatureProvider.isAvailable(.receiveENS) {
            let options = ReceiveMainViewModel.Options(
                tokenItem: tokenItem,
                flow: flow,
                addressTypesProvider: addressTypesProvider,
                // [REDACTED_TODO_COMMENT]
                isYieldModuleActive: isYieldModuleActive
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
        let notificationInputs = receiveBottomSheetNotificationInputsFactory.makeNotificationInputs(
            for: tokenItem,
            isYieldModuleActive: isYieldModuleActive
        )

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
            addressTypesProvider: addressTypesProvider,
            isYieldModuleActive: isYieldModuleActive
        )
    }
}

extension AvailabilityReceiveFlowFactory {
    enum AvailabilityViewModel {
        case domainReceiveFlow(ReceiveMainViewModel)
        case bottomSheetReceiveFlow(ReceiveBottomSheetViewModel)
    }
}
