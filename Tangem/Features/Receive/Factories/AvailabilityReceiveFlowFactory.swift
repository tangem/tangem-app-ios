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

    func makeAvailabilityReceiveFlow() -> ReceiveMainViewModel {
        let options = ReceiveMainViewModel.Options(
            tokenItem: tokenItem,
            flow: flow,
            addressTypesProvider: addressTypesProvider,
            // [REDACTED_TODO_COMMENT]
            isYieldModuleActive: isYieldModuleActive
        )

        let receiveMainViewModel = ReceiveMainViewModel(options: options)
        receiveMainViewModel.start()

        return receiveMainViewModel
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
