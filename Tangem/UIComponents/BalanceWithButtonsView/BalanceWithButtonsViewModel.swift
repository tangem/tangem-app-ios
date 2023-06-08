//
//  BalanceWithButtonsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class BalanceWithButtonsViewModel: ObservableObject, Identifiable {
    @Published var isLoadingFiatBalance = true
    @Published var isLoadingBalance = true
    @Published var fiatBalance = NSAttributedString(string: "")
    @Published var cryptoBalance = ""

    @Published var buttons: [ButtonWithIconInfo] = []

    private let balanceProvider: BalanceProvider
    private let buttonsProvider: ActionButtonsProvider

    private var fiatUpdatingTask: Task<Void, Never>?
    private var bag = Set<AnyCancellable>()

    init(balanceProvider: BalanceProvider, buttonsProvider: ActionButtonsProvider) {
        self.balanceProvider = balanceProvider
        self.buttonsProvider = buttonsProvider

        bind()
    }

    private func bind() {
        balanceProvider.balancePublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] balanceState in
                switch balanceState {
                case .loading:
                    return
                case .loaded(let balance):
                    self?.updateBalances(for: balance)
                case .failedToLoad(let error):
                    AppLog.shared.debug("Failed to load balance. Reason: \(error)")
                    self?.setupEmptyBalances()
                    self?.isLoadingFiatBalance = false
                }
                self?.isLoadingBalance = false
            })
            .store(in: &bag)

        buttonsProvider.buttonsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] buttons in
                guard let self else { return }

                self.buttons = buttons
            }
            .store(in: &bag)
    }

    private func setupEmptyBalances() {
        fiatBalance = .init(string: BalanceFormatter.defaultEmptyBalanceString)
        cryptoBalance = BalanceFormatter.defaultEmptyBalanceString
    }

    private func updateBalances(for newBalance: BalanceInfo) {
        let formatter = BalanceFormatter()

        cryptoBalance = formatter.formatCryptoBalance(newBalance.balance, formattingOptions: .makeDefaultCryptoFormattingOptions(for: newBalance.currencyCode))

        fiatUpdatingTask?.cancel()
        fiatUpdatingTask = Task { [weak self] in
            let converter = BalanceConverter()
            let fiatFormattingOptions = BalanceFormattingOptions.defaultFiatFormattingOptions

            do {
                let fiatBalance = try await converter.convertToFiat(value: newBalance.balance, from: newBalance.currencyCode, to: fiatFormattingOptions.currencyCode)
                let formattedFiat = formatter.formatFiatBalance(fiatBalance, formattingOptions: .defaultFiatFormattingOptions)
                let attributedFiatBalance = formatter.formatTotalBalanceForMain(fiatBalance: formattedFiat, formattingOptions: .defaultOptions)

                await runOnMain {
                    self?.fiatBalance = attributedFiatBalance
                }
            } catch {
                AppLog.shared.debug("Failed to convert from crypto to fiat. Reason: \(error)")
            }

            await runOnMain {
                self?.isLoadingFiatBalance = false
            }
        }
    }
}
