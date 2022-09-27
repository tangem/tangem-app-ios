//
//  TotalSumBalanceViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

class TotalSumBalanceViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var isLoading: Bool = true
    @Published var totalFiatValueString: NSAttributedString = NSAttributedString(string: "")
    @Published var hasError: Bool = false

    /// If we have a note or any single coin wallet that we should show this balance
    @Published var singleWalletBalance: String?

    // MARK: - Private

    @Injected(\.rateAppService) private var rateAppService: RateAppService
    private let tapOnCurrencySymbol: () -> ()
    private let isSingleCoinCard: Bool
    private let userWalletModel: UserWalletModel
    private let totalBalanceManager: TotalBalanceProviding

    private var bag: Set<AnyCancellable> = []

    init(
        userWalletModel: UserWalletModel,
        totalBalanceManager: TotalBalanceProviding,
        isSingleCoinCard: Bool,
        tapOnCurrencySymbol: @escaping () -> ()
    ) {
        self.userWalletModel = userWalletModel
        self.totalBalanceManager = totalBalanceManager
        self.isSingleCoinCard = isSingleCoinCard
        self.tapOnCurrencySymbol = tapOnCurrencySymbol

        bind()
    }

    func updateBalance() {
        totalBalanceManager.updateTotalBalance()
    }

    func updateForSingleCoinCard(tokenModels: [TokenItemViewModel]) {
        guard isSingleCoinCard else { return }

        singleWalletBalance = tokenModels.first?.balance
    }

    func didTapOnCurrencySymbol() {
        tapOnCurrencySymbol()
    }

    func beginUpdates() {
        tapOnCurrencySymbol()
    }

    private func bind() {
        userWalletModel.subscribeToWalletModels()
            .map { [unowned self] walletModels in
                isLoading = true

                return walletModels
                    .map { $0.$tokenItemViewModels }
                    .combineLatest()
                    .map { $0.reduce([], +) }
                    // Update total balance only after all models succesfully loaded
                    .filter { $0.allConforms { $0.state.isSuccesfullyLoaded } }
            }
            .switchToLatest()
            // Hack with delay until rebuild the "update flow" in WalletModel
            .delay(for: 0.2, scheduler: DispatchQueue.main)
            .sink { [unowned self] walletModels in
                updateForSingleCoinCard(tokenModels: walletModels)
                updateBalance()
            }
            .store(in: &bag)

        totalBalanceManager.totalBalancePublisher()
            .compactMap { $0.value }
            .map { [unowned self] balance in
                addAttributeForBalance(balance.balance, withCurrencyCode: balance.currency.code)
            }
            .weakAssign(to: \.totalFiatValueString, on: self)
            .store(in: &bag)

        totalBalanceManager.totalBalancePublisher()
            .compactMap { $0.value?.hasError }
            .removeDuplicates()
            .weakAssign(to: \.hasError, on: self)
            .store(in: &bag)

        totalBalanceManager.totalBalancePublisher()
            .map { $0.isLoading }
            .filter { !$0 }
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .weakAssignAnimated(to: \.isLoading, on: self)
            .store(in: &bag)
    }

    private func addAttributeForBalance(_ balance: Decimal, withCurrencyCode: String) -> NSAttributedString {
        let formattedTotalFiatValue = balance.currencyFormatted(code: withCurrencyCode)

        let attributedString = NSMutableAttributedString(string: formattedTotalFiatValue)
        let allStringRange = NSRange(location: 0, length: attributedString.length)
        attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 28, weight: .semibold), range: allStringRange)

        let decimalLocation = NSString(string: formattedTotalFiatValue).range(of: balance.decimalSeparator()).location
        if decimalLocation < (formattedTotalFiatValue.count - 1) {
            let locationAfterDecimal = decimalLocation + 1
            let symbolsAfterDecimal = formattedTotalFiatValue.count - locationAfterDecimal
            let rangeAfterDecimal = NSRange(location: locationAfterDecimal, length: symbolsAfterDecimal)

            attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 20, weight: .semibold), range: rangeAfterDecimal)
        }

        return attributedString
    }

    private func checkPositiveBalance() {
        guard rateAppService.shouldCheckBalanceForRateApp else { return }

        guard userWalletModel.getWalletModels().contains(where: { !$0.wallet.isEmpty }) else { return }

        rateAppService.registerPositiveBalanceDate()
    }
}
