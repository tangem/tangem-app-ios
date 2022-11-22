//
//  CurrencySelectViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class CurrencySelectViewModel: ObservableObject {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    var dismissAfterSelection: Bool = true

    @Published var loading: Bool = false
    @Published var currencies: [CurrenciesResponse.Currency] = []
    @Published var error: AlertBinder?

    private var bag = Set<AnyCancellable>()

    func onAppear() {
        loading = true
        tangemApiService
            .loadCurrencies()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.error = error.alertBinder
                }
                self?.loading = false
            }, receiveValue: { [weak self] currencies in
                self?.currencies = currencies
                    .sorted {
                        $0.description < $1.description
                    }
            })
            .store(in: &self.bag)
    }

    func isSelected(_ currency: CurrenciesResponse.Currency) -> Bool {
        AppSettings.shared.selectedCurrencyCode == currency.code
    }

    func onSelect(_ currency: CurrenciesResponse.Currency) {
        Analytics.log(.mainCurrencyChanged, params: [.currency: currency.name])
        objectWillChange.send()
        AppSettings.shared.selectedCurrencyCode = currency.code
    }
}
