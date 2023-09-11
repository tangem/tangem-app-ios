//
//  TotalSumBalanceViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import CombineExt
import BlockchainSdk

class TotalSumBalanceViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var isLoading: Bool = true
    @Published var totalFiatValueString: NSAttributedString = .init(string: "")
    @Published var hasError: Bool = false

    // MARK: - Private

    @Injected(\.rateAppService) private var rateAppService: RateAppService
    private unowned let tapOnCurrencySymbol: OpenCurrencySelectionDelegate
    private let walletModelsManager: WalletModelsManager
    private var totalBalanceProvider: TotalBalanceProviding

    private var bag: Set<AnyCancellable> = []

    init(
        totalBalanceProvider: TotalBalanceProviding,
        walletModelsManager: WalletModelsManager,
        tapOnCurrencySymbol: OpenCurrencySelectionDelegate
    ) {
        self.totalBalanceProvider = totalBalanceProvider
        self.walletModelsManager = walletModelsManager
        self.tapOnCurrencySymbol = tapOnCurrencySymbol
        bind()
    }

    func didTapOnCurrencySymbol() {
        tapOnCurrencySymbol.openCurrencySelection()
    }

    private func bind() {
        totalBalanceProvider.totalBalancePublisher()
            .compactMap { $0.value }
            .map { [unowned self] balance -> NSAttributedString in
                checkPositiveBalance()
                return addAttributeForBalance(balance)
            }
            .assign(to: \.totalFiatValueString, on: self, ownership: .weak)
            .store(in: &bag)

        // Skeleton subscription
        totalBalanceProvider.totalBalancePublisher()
            .map { $0.isLoading }
            .assign(to: \.isLoading, on: self, ownership: .weak)
            .store(in: &bag)

        totalBalanceProvider.totalBalancePublisher()
            .compactMap { $0.value?.hasError }
            .removeDuplicates()
            .assign(to: \.hasError, on: self, ownership: .weak)
            .store(in: &bag)
    }

    private func addAttributeForBalance(_ totalValue: TotalBalanceProvider.TotalBalance) -> NSAttributedString {
        let balanceFormatter = BalanceFormatter()
        let formattedTotalFiatValue = balanceFormatter.formatFiatBalance(totalValue.balance, formattingOptions: .defaultFiatFormattingOptions)
        return balanceFormatter.formatTotalBalanceForMain(fiatBalance: formattedTotalFiatValue, formattingOptions: .defaultOptions)
    }

    private func checkPositiveBalance() {
        guard rateAppService.shouldCheckBalanceForRateApp else { return }

        guard walletModelsManager.walletModels.contains(where: { !$0.wallet.isEmpty }) else { return }

        rateAppService.registerPositiveBalanceDate()
    }
}
