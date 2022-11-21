//
//  TotalSumBalanceViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import BlockchainSdk

class TotalSumBalanceViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var isLoading: Bool = true
    @Published var totalFiatValueString: NSAttributedString = NSAttributedString(string: "")
    @Published var hasError: Bool = false

    /// If we have a note or any single coin wallet that we should show this balance
    @Published var singleWalletBalance: String?

    // MARK: - Private

    @Injected(\.rateAppService) private var rateAppService: RateAppService
    private unowned let tapOnCurrencySymbol: OpenCurrencySelectionDelegate
    private let cardAmountType: Amount.AmountType?
    private let userWalletModel: UserWalletModel
    private let totalBalanceManager: TotalBalanceProviding

    private var bag: Set<AnyCancellable> = []

    init(
        userWalletModel: UserWalletModel,
        totalBalanceManager: TotalBalanceProviding,
        cardAmountType: Amount.AmountType?,
        tapOnCurrencySymbol: OpenCurrencySelectionDelegate
    ) {
        self.userWalletModel = userWalletModel
        self.totalBalanceManager = totalBalanceManager
        self.cardAmountType = cardAmountType
        self.tapOnCurrencySymbol = tapOnCurrencySymbol
        bind()
    }

    func updateForSingleCoinCard() {
        guard let cardAmountType = self.cardAmountType else { return }
        let walletModels = userWalletModel.getWalletModels()

        singleWalletBalance = walletModels.first?.allTokenItemViewModels().first(where: { $0.amountType == cardAmountType })?.balance
    }

    func didTapOnCurrencySymbol() {
        tapOnCurrencySymbol.openCurrencySelection()
    }

    private func bind() {
        // Total balance main subscription
        totalBalanceManager.totalBalancePublisher()
            .compactMap { $0.value }
            .map { [unowned self] balance in
                checkPositiveBalance()
                updateForSingleCoinCard()
                return addAttributeForBalance(balance.balance, withCurrencyCode: balance.currencyCode)
            }
            .weakAssign(to: \.totalFiatValueString, on: self)
            .store(in: &bag)

        let hasErrorInUpdate = totalBalanceManager.totalBalancePublisher()
            .compactMap { $0.value?.hasError }

        let hasEntriesWithoutDerivation = userWalletModel
            .subscribeToEntriesWithoutDerivation()
            .map { !$0.isEmpty }

        Publishers.CombineLatest(hasErrorInUpdate, hasEntriesWithoutDerivation)
            .map { $0 || $1 }
            .removeDuplicates()
            .weakAssign(to: \.hasError, on: self)
            .store(in: &bag)

        // Skeleton subscription
        totalBalanceManager.totalBalancePublisher()
            .map { $0.isLoading }
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
