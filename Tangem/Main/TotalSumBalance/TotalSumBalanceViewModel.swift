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
    private var tokenItemsViewModel: [TokenItemViewModel] = []
    
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
        tokenItemsViewModel = tokens
        refresh()
    }
    
    func updateIfNeeded(with tokens: [TokenItemViewModel]) {
        if tokenItemsViewModel == tokens || isLoading {
            return
        }
        tokenItemsViewModel = tokens
        refresh(loadingAnimationEnable: false)
    }
    
    func disableLoading(animation: Bool = false) {
        if animation {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isFailed = true
                self.isLoading = false
            }
        } else {
            withAnimation(Animation.spring().delay(0.5)) {
                self.isLoading = false
            }
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
                self.tokenItemsViewModel.forEach { token in
                    if token.state.isSuccesfullyLoaded {
                        totalFiatValue += token.fiatValue
                    } else {
                        hasError = true
                    }
                }
                
                if hasError {
                    self.totalFiatValueString = "—"
                } else {
                    self.totalFiatValueString = totalFiatValue.currencyFormatted(code: currency.code)
                }
                
                if loadingAnimationEnable {
                    self.disableLoading(animation: hasError)
                } else {
                    self.isFailed = hasError
                }
            }.store(in: &bag)
    }
}
