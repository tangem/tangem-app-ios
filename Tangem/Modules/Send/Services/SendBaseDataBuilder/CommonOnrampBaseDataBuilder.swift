//
//  CommonOnrampBaseDataBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemExpress

protocol OnrampBaseDataBuilderInput {}

struct CommonOnrampBaseDataBuilder: OnrampBaseDataBuilder {
    private let input: OnrampBaseDataBuilderInput
    private let walletModel: WalletModel
    private let onrampRepository: OnrampRepository

    init(
        input: OnrampBaseDataBuilderInput,
        walletModel: WalletModel,
        onrampRepository: OnrampRepository
    ) {
        self.input = input
        self.walletModel = walletModel
        self.onrampRepository = onrampRepository
    }

    func makeDataForOnrampCountryBottomSheet() -> any TangemExpress.OnrampRepository {
        onrampRepository
    }
}
