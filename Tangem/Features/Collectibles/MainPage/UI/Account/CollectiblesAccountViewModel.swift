//
//  CollectiblesAccountViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemCollectibles
import TangemFoundation
import TangemLocalization
import TangemUI
import TangemUIUtils

@MainActor
final class CollectiblesAccountViewModel: ObservableObject {
    // MARK: - Properties

    private let accountModel: (any CollectiblesBalanceSource & CollectiblesVaultUsdcAccountProvider)?
    private weak var routable: (any CollectiblesAccountRoutable)?

    private var didLoad = false

    // MARK: - Publishers

    @Published private(set) var summary: CollectiblesAccountView.Summary = .placeholder
    @Published private(set) var vaultUsdcState: CollectiblesVaultUsdcState = .loading
    @Published var alert: AlertBinder?
    @Published private var isRefreshing = false

    // MARK: - Init

    init(
        accountModel: (any CollectiblesBalanceSource & CollectiblesVaultUsdcAccountProvider)?,
        routable: (any CollectiblesAccountRoutable)?
    ) {
        self.accountModel = accountModel
        self.routable = routable

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

    func addFunds() {
        switch vaultUsdcState {
        case .ready(let account):
            routable?.openAddFunds(account: account)
        case .loading:
            break
        case .missing:
            alert = AlertBuilder.makeOkGotItAlert(message: Localization.commonSomethingWentWrong)
        case .failed:
            alert = AlertBuilder.makeOkGotItAlert(message: Localization.commonSomethingWentWrong) { [weak self] in
                Task { await self?.refresh() }
            }
        }
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

        accountModel.vaultUsdcStatePublisher
            .receiveOnMain()
            .assign(to: &$vaultUsdcState)
    }
}
