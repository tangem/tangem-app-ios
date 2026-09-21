//
//  CollectiblesAccountViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemLocalization
import TangemUI

@MainActor
final class CollectiblesAccountViewModel: ObservableObject {
    // MARK: - Properties

    private let accountModel: (any CollectiblesBalanceSource)?

    private var didLoad = false

    // MARK: - Publishers

    @Published private(set) var summary: CollectiblesAccountView.Summary = .placeholder
    @Published private var isRefreshing = false

    // MARK: - Init

    init(accountModel: (any CollectiblesBalanceSource)?) {
        self.accountModel = accountModel

        bind()
    }

    // MARK: - Methods

    func load() async {
        guard !didLoad else {
            return
        }

        didLoad = true

        await refresh()
    }

    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }

        await accountModel?.refreshState()
    }
}

// MARK: - Private logic

private extension CollectiblesAccountViewModel {
    func bind() {
        guard let accountModel else {
            return
        }

        Publishers
            .CombineLatest3(
                accountModel.fiatTotalTokenBalanceProvider.formattedBalanceTypePublisher,
                accountModel.usdcTokenBalanceProvider.balanceTypePublisher,
                $isRefreshing
            )
            .receiveOnMain()
            .map { fiat, usdc, isRefreshing in Mapper.map(fiat: fiat, usdc: usdc, isRefreshing: isRefreshing) }
            .assign(to: &$summary)
    }
}
