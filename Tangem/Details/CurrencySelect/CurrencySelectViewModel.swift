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
            .mapError { _ in
                CurrencySelectorError.failedToLoad
            }
            .sink(receiveCompletion: {[weak self] completion in
                if case let .failure(error) = completion {
                    self?.error = error.alertBinder
                }
                self?.loading = false
            }, receiveValue: {[weak self] currencies in
                self?.currencies = currencies
                    .sorted {
                        $0.description < $1.description
                    }
            })
            .store(in: &self.bag)
    }
}

extension CurrencySelectViewModel {
    enum CurrencySelectorError: Error, LocalizedError {
        case failedToLoad
        
        var errorDescription: String? {
            switch self {
            case .failedToLoad:
                return "currency_select_failed_to_load".localized
            }
        }
    }
}
