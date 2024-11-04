//
//  OnrampAmountBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

struct OnrampAmountBuilder {
    typealias IO = (input: OnrampAmountInput, output: OnrampAmountOutput)
    typealias ReturnValue = (viewModel: OnrampAmountViewModel, interactor: OnrampAmountInteractor)

    private let walletModel: WalletModel
    private let builder: SendDependenciesBuilder

    init(walletModel: WalletModel, builder: SendDependenciesBuilder) {
        self.walletModel = walletModel
        self.builder = builder
    }

    func makeOnrampAmountViewModel(io: IO) -> ReturnValue {
        let interactor = makeOnrampAmountInteractor(io: io)
        let viewModel = OnrampAmountViewModel(tokenItem: walletModel.tokenItem, interactor: interactor)

        return (viewModel: viewModel, interactor: interactor)
    }
}

// MARK: - Private

private extension OnrampAmountBuilder {
    func makeOnrampAmountInteractor(io: IO) -> OnrampAmountInteractor {
        CommonOnrampAmountInteractor(
            input: io.input,
            output: io.output,
            tokenItem: walletModel.tokenItem,
            validator: builder.makeOnrampAmountValidator()
        )
    }
}
