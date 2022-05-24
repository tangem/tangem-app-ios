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
    @Published var totalFiatValueString: String = ""
    @Published var isFailed: Bool = false
    
    private var bag = Set<AnyCancellable>()
    private var tokenItems: [TokenItemViewModel] = []
    
    init() {
        currencyType = currencyRateService.selectedCurrencyCode
    }
    
    func beginUpdates() {
        self.isLoading = true
    }
    
    func update(with tokens: [TokenItemViewModel]) {
        tokenItems = tokens
        refresh()
    }
    
    func updateIfNeeded(with tokens: [TokenItemViewModel]) {
        if tokenItems == tokens || isLoading {
            return
        }
        tokenItems = tokens
        refresh(with: false)
    }
    
    func disableLoading(with failed: Bool = false) {
        if failed {
            isFailed = true
            isLoading = false
        } else {
            withAnimation(Animation.spring().delay(0.5)) {
                self.isLoading = false
            }
        }
    }
    
    private func refresh(with loadingAnimation: Bool = true) {
        isFailed = false
        currencyType = currencyRateService.selectedCurrencyCode
        var hasBlockchainError = false
        currencyRateService
            .baseCurrencies()
            .receive(on: RunLoop.main)
            .sink { _ in
            } receiveValue: { currencies in
                guard let currency = currencies.first(where: { $0.code == self.currencyRateService.selectedCurrencyCode }) else { return }
                var totalFiatValue: Decimal = 0.0
                self.tokenItems.forEach { token in
                    if token.state.isSuccesfullyLoaded {
                        totalFiatValue += token.fiatValue
                    } else {
                        hasBlockchainError = true
                    }
                }
                
                if hasBlockchainError {
                    self.totalFiatValueString = ""
                } else {
                    self.totalFiatValueString = totalFiatValue.currencyFormatted(code: currency.code)
                }
                
                if loadingAnimation {
                    self.disableLoading(with: hasBlockchainError)
                } else {
                    self.isFailed = hasBlockchainError
                }
            }.store(in: &bag)
    }
}
