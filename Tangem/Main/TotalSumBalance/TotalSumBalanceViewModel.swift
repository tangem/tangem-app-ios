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
    @Published var isFailed: Bool = false
    
    private var bag = Set<AnyCancellable>()
    private var tokenItemViewModels: [TokenItemViewModel] = []
    
    init() {
        currencyType = currencyRateService.selectedCurrencyCode
    }
    
    func beginUpdates() {
        DispatchQueue.main.async {
            self.isLoading = true
            self.isFailed = false
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
        withAnimation(Animation.spring().delay(0.5)) {
            if withError {
                self.isFailed = true
            }
            self.isLoading = false
        }
    }
    
    private func refresh(loadingAnimationEnable: Bool = true) {
        isFailed = false
        currencyType = currencyRateService.selectedCurrencyCode
        currencyRateService
            .baseCurrencies()
            .receive(on: RunLoop.main)
            .sink { _ in
            } receiveValue: { currencies in
                guard let currency = currencies.first(where: { $0.code == self.currencyRateService.selectedCurrencyCode }) else { return }
                var hasError = false
                var totalFiatValue: Decimal = 0.0
                self.tokenItemViewModels.forEach { token in
                    if token.state.isSuccesfullyLoaded {
                        totalFiatValue += token.fiatValue
                    } else {
                        hasError = true
                    }
                }
                
                if hasError {
                    self.totalFiatValueString = NSMutableAttributedString(string: "—")
                } else {
                    self.totalFiatValueString = self.addAttributeForBalance(totalFiatValue, withCurrencyCode: currency.code)
                }
                
                if loadingAnimationEnable {
                    self.disableLoading(withError: hasError)
                } else {
                    self.isFailed = hasError
                }
            }.store(in: &bag)
    }
    
    private func addAttributeForBalance(_ balance: Decimal, withCurrencyCode: String) -> NSAttributedString {
        let formattedTotalFiatValue = balance.currencyFormatted(code: withCurrencyCode)
        
        let attributedString = NSMutableAttributedString(string: formattedTotalFiatValue)
        let allStringRange = NSRange(location: 0, length: attributedString.length)
        attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 28, weight: .semibold), range: allStringRange)
        
        let decimalLocation = NSString(string: formattedTotalFiatValue).range(of: balance.decimalSeparator()).location + 1
        let symbolsAfterDecimal = "\(formattedTotalFiatValue.split(separator: Character(balance.decimalSeparator())).last ?? Substring(""))"
        let rangeAfterDecimal = NSRange(location: decimalLocation, length: symbolsAfterDecimal.count)
        
        attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 20, weight: .semibold), range: rangeAfterDecimal)
        return attributedString
    }
}
