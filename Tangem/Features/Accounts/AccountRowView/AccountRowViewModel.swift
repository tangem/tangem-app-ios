//
//  AccountRowViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemAccounts
import SwiftUI

@MainActor
final class AccountRowViewModel: ObservableObject {
    // MARK: Published Properties

    let iconData: AccountIconView.ViewData
    let name: String
    let subtitle: String
    @Published private(set) var balanceState: LoadableTokenBalanceView.State?

    // MARK: Private Properties

    private var bag = Set<AnyCancellable>()

    init(input: Input) {
        iconData = input.iconData
        name = input.name
        subtitle = input.subtitle
        balanceState = nil

        bind(balancePublisher: input.balancePublisher)
    }

    // MARK: Private Methods

    private func bind(balancePublisher: AnyPublisher<LoadableTokenBalanceView.State, Never>?) {
        guard let balancePublisher = balancePublisher else { return }

        balancePublisher
            .withWeakCaptureOf(self)
            .sink { viewModel, balanceState in
                viewModel.balanceState = balanceState == .empty ? nil : balanceState
            }
            .store(in: &bag)
    }
}

// MARK: - Input

extension AccountRowViewModel {
    struct Input {
        let iconData: AccountIconView.ViewData
        let name: String
        let subtitle: String
        let balancePublisher: AnyPublisher<LoadableTokenBalanceView.State, Never>?

        init(
            iconData: AccountIconView.ViewData,
            name: String,
            subtitle: String,
            balancePublisher: AnyPublisher<LoadableTokenBalanceView.State, Never>? = nil
        ) {
            self.iconData = iconData
            self.name = name
            self.subtitle = subtitle
            self.balancePublisher = balancePublisher
        }
    }
}
