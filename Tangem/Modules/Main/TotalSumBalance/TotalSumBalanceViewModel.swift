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
    @Injected(\.currencyRateService) private var currencyRateService: CurrencyRateService
    
    @Published var isLoading: Bool = false
    @Published var currencyType: String = ""
    @Published var totalFiatValueString: NSAttributedString = NSAttributedString(string: "")
    @Published var hasError: Bool = false
    
    private var refreshSubscription: AnyCancellable?
    private var tokenItemViewModels: [TokenItemViewModel] = []
    
    init() {
        currencyType = currencyRateService.selectedCurrencyCode
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
        currencyType = currencyRateService.selectedCurrencyCode
        refreshSubscription = currencyRateService
            .baseCurrencies()
            .receive(on: RunLoop.main)
            .sink { _ in
            } receiveValue: { [weak self] currencies in
                guard let self = self,
                      let currency = currencies.first(where: { $0.code == self.currencyRateService.selectedCurrencyCode })
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
