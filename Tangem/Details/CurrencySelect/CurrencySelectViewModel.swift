//
//  CurrencySelectViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class CurrencySelectViewModel: ViewModel, ObservableObject {
    weak var assembly: Assembly!
    weak var ratesService: CurrencyRateService!
    weak var navigation: NavigationCoordinator!
    
    @Published var loading: Bool = false
    @Published var currencies: [FiatCurrency] = []
    @Published var error: AlertBinder?
    
    private var bag = Set<AnyCancellable>()
    
    func onAppear() {
        loading = true
        ratesService
            .baseCurrencies()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: {[weak self] completion in
                if case let .failure(error) = completion {
                    self?.error = error.alertBinder
                }
                self?.loading = false
            }, receiveValue: {[weak self] currencies in
                self?.currencies = currencies
            })
            .store(in: &self.bag)
    }
}
