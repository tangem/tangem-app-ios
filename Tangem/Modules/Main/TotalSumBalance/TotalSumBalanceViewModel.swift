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
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    @Published var isLoading: Bool
    @Published var totalFiatValueString: NSAttributedString
    @Published var hasError: Bool
    @Published var isSingleCoinCard: Bool
    @Published var isCurrencySelectionVisible: Bool
    /// If we have a note or any single coin wallet that we should show this balance
    @Published var tokenItemViewModel: TokenItemViewModel?
    let tapOnCurrencySymbol: () -> ()

    private var refreshSubscription: AnyCancellable?
    private var tokenItemViewModels: [TokenItemViewModel] = [] {
        didSet {
            // Need to refactoring it
            if isSingleCoinCard, let coinModel = tokenItemViewModels.first {
                tokenItemViewModel = coinModel
            }
        }
    }

    init(isLoading: Bool = false,
         totalFiatValueString: NSAttributedString = NSAttributedString(string: ""),
         hasError: Bool = false,
         isSingleCoinCard: Bool,
         isCurrencySelectionVisible: Bool,
         tapOnCurrencySymbol: @escaping () -> ()
    ) {
        self.isLoading = isLoading
        self.totalFiatValueString = totalFiatValueString
        self.hasError = hasError
        self.isSingleCoinCard = isSingleCoinCard
        self.isCurrencySelectionVisible = isCurrencySelectionVisible
        self.tapOnCurrencySymbol = tapOnCurrencySymbol
    }

    func beginUpdates() {
        DispatchQueue.main.async {
            self.isLoading = true
            self.hasError = false
        }
    }

    func update(with tokens: [TokenItemViewModel]) {
        tokenItemViewModels = tokens
        refresh()
    }

    func updateIfNeeded(with tokens: [TokenItemViewModel]) {
        if tokenItemViewModels == tokens || isLoading {
            return
        }
        tokenItemViewModels = tokens
        refresh(loadingAnimationEnable: false)
    }

    func disableLoading(withError: Bool = false) {
        withAnimation(Animation.spring()) {
            self.hasError = withError
            self.isLoading = false
        }
    }

    private func refresh(loadingAnimationEnable: Bool = true) {
        refreshSubscription = tangemApiService
            .loadCurrencies()
            .receive(on: RunLoop.main)
            .sink { _ in } receiveValue: { [weak self] currencies in
                guard let self = self,
                      let currency = currencies.first(where: { $0.code == AppSettings.shared.selectedCurrencyCode })
                else {
                    return
                }
                var hasTotalBalanceError: Bool = false
                var totalFiatValue: Decimal = 0.0
                for token in self.tokenItemViewModels {
                    if token.state.isSuccesfullyLoaded {
                        totalFiatValue += token.fiatValue
                    }

                    if token.rate.isEmpty || !token.state.isSuccesfullyLoaded {
                        hasTotalBalanceError = true
                    }
                }

                self.totalFiatValueString = self.addAttributeForBalance(totalFiatValue, withCurrencyCode: currency.code)

                if loadingAnimationEnable {
                    self.disableLoading(withError: hasTotalBalanceError)
                } else {
                    if !self.isLoading && self.tokenItemViewModels.first(where: { $0.displayState == .busy }) == nil {
                        self.hasError = hasTotalBalanceError
                    }
                }
            }
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
}
