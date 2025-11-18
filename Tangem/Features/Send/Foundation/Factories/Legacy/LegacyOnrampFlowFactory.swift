//
//  LegacyOnrampFlowFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking
import TangemFoundation

struct LegacyOnrampFlowFactory: SendGenericFlowFactory {
    private let walletInfo: UserWalletInfo
    private let walletModel: any WalletModel
    private let parameters: PredefinedOnrampParameters
    private let source: SendCoordinator.Source

    private let builder: SendDependenciesBuilder

    init(input: SendDependenciesBuilder.Input, parameters: PredefinedOnrampParameters, source: SendCoordinator.Source) {
        walletInfo = input.userWalletInfo
        walletModel = input.walletModel

        self.parameters = parameters
        self.source = source

        builder = SendDependenciesBuilder(input: input)
    }

    func make(router: any SendRoutable) -> SendViewModel {
        let onrampStepBuilder = OnrampStepBuilder(walletModel: walletModel)
        let onrampAmountBuilder = OnrampAmountBuilder(walletModel: walletModel, builder: builder)

        let baseBuilder = OnrampFlowBaseBuilder(
            walletModel: walletModel,
            source: source,
            onrampAmountBuilder: onrampAmountBuilder,
            onrampStepBuilder: onrampStepBuilder,
            builder: builder
        )

        return baseBuilder.makeSendViewModel(parameters: parameters, router: router)
    }
}
