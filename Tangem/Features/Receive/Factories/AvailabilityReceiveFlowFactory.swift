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

    func makeAvailabilityReceiveFlow() -> ReceiveMainViewModel {
        let options = ReceiveMainViewModel.Options(
            tokenItem: tokenItem,
            flow: flow,
            addressTypesProvider: addressTypesProvider
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
            addressTypesProvider: addressTypesProvider
        )
    }
}
