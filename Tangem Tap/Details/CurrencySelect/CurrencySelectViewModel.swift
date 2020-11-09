//
//  CurrencySelectViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class CurrencySelectViewModel: ViewModel {
    var assembly: Assembly!
    var ratesService: CoinMarketCapService!
    
    @Published var navigation: NavigationCoordinator! {
        didSet {
            navigation.objectWillChange
                .receive(on: RunLoop.main)
                .sink { [weak self] in
                    self?.objectWillChange.send()
                }
                .store(in: &bag)
        }
    }
    
    @Published private(set) var loading: Bool = false
    @Published private(set) var currencies: [FiatCurrency] = []
    @Published var error: AlertBinder?
    
    private var bag = Set<AnyCancellable>()
    
    func onAppear() {
        loading = true
        ratesService
            .loadFiatMap()
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
