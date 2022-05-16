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
    
    var tokens: Published<[TokenItemViewModel]>.Publisher
    @Published var isLoading: Bool = false
    @Published var currencyType: String = ""
    @Published var totalFiatValueString: String = ""
    
    private var bag = Set<AnyCancellable>()
    private var currencyRateService: CurrencyRateService
    private var tokenItems: [TokenItemViewModel] = []
    
    init(currencyRateService: CurrencyRateService, tokens: Published<[TokenItemViewModel]>.Publisher) {
        self.tokens = tokens
        self.currencyRateService = currencyRateService
        bind()
    }
    
    func bind() {
        tokens.sink { [weak self] newValue in
            guard let tokenItem = self?.tokenItems else { return }
            if newValue == tokenItem && !tokenItem.isEmpty {
                return
            }
            self?.tokenItems = newValue
            self?.refresh()
        }.store(in: &bag)
    }
    
    func refresh() {
        guard !isLoading
        else {
            return
        }
        withAnimation {
            isLoading = true
        }
        currencyType = currencyRateService.selectedCurrencyCode
        currencyRateService
            .baseCurrencies()
            .receive(on: RunLoop.main)
            .sink { _ in
                
            } receiveValue: { currencies in
                guard let currency = currencies.first(where: { $0.code == self.currencyRateService.selectedCurrencyCode }) else { return }
                var countFiatValue: Decimal = 0.0
                self.tokenItems.forEach { token in
                    countFiatValue += token.fiatValue
                }
                self.totalFiatValueString = "\(currency.unit) \(countFiatValue)"
                self.disableLoading()
            }.store(in: &bag)
    }
    
    func disableLoading() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation {
                self.isLoading = false
            }
        }
    }
}
