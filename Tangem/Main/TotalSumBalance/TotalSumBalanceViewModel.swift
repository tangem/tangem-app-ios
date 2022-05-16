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
    
    var tokens: Published<[TokenItemViewModel]>.Publisher
    @Published var isLoading: Bool = false
    @Published var currencyType: String = ""
    @Published var totalFiatValueString: String = ""
    
    private var bag = Set<AnyCancellable>()
    private var tokenItems: [TokenItemViewModel] = []
    
    init(tokens: Published<[TokenItemViewModel]>.Publisher) {
        self.tokens = tokens
        bind()
    }
    
    func bind() {
        tokens.sink { [weak self] newValue in
            guard let tokenItem = self?.tokenItems else { return }
            if newValue == tokenItem && !tokenItem.isEmpty {
                return
            }
            self?.tokenItems = newValue
            DispatchQueue.main.async {
                self?.refresh()
            }
        }.store(in: &bag)
    }
    
    func refresh() {
        guard !isLoading
        else {
            return
        }
        isLoading = true
        currencyType = currencyRateService.selectedCurrencyCode
        currencyRateService
            .baseCurrencies()
            .receive(on: RunLoop.main)
            .sink { _ in
                
            } receiveValue: { currencies in
                guard let currency = currencies.first(where: { $0.code == self.currencyRateService.selectedCurrencyCode }) else { return }
                var totalFiatValue: Decimal = 0.0
                self.tokenItems.forEach { token in
                    totalFiatValue += token.fiatValue
                }
                
                let formatter = self.currencyValue(code: currency.code)
                
                self.totalFiatValueString = formatter.string(from: NSDecimalNumber(decimal: totalFiatValue)) ?? ""
                
                self.disableLoading()
            }.store(in: &bag)
    }
    
    func disableLoading() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isLoading = false
        }
    }
    
    private func currencyValue(code: String) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.currencyCode = code
        return formatter
    }
    
}
