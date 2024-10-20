//
//  CommonOnrampBaseDataBuilder.swift
//  TangemApp
//
//  Created by Sergey Balashov on 20.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemExpress

protocol OnrampBaseDataBuilderInput {
    var onrampRepository: OnrampRepository { get }
}

struct CommonOnrampBaseDataBuilder: OnrampBaseDataBuilder {
    private let input: OnrampBaseDataBuilderInput
    private let walletModel: WalletModel
    private let emailDataProvider: EmailDataProvider

    init(
        input: OnrampBaseDataBuilderInput,
        walletModel: WalletModel,
        emailDataProvider: EmailDataProvider
    ) {
        self.input = input
        self.walletModel = walletModel
        self.emailDataProvider = emailDataProvider
    }

    func makeDataForOnrampCountryBottomSheet() -> any TangemExpress.OnrampRepository {
        input.onrampRepository
    }
}
