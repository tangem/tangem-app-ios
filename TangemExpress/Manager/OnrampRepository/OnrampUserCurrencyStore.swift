//
//  OnrampUserCurrencyStore.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

public final class OnrampUserCurrencyStore {
    private let storage: OnrampStorage
    private let subject: CurrentValueSubject<OnrampFiatCurrency?, Never>

    public init(storage: OnrampStorage) {
        self.storage = storage

        subject = .init(storage.preference()?.currency?.fiatCurrency)
    }

    var currency: OnrampFiatCurrency? {
        subject.value
    }

    var currencyPublisher: AnyPublisher<OnrampFiatCurrency?, Never> {
        subject.eraseToAnyPublisher()
    }

    func save(_ currency: OnrampFiatCurrency) {
        storage.save(preference: OnrampUserPreference(currency: .init(currency)))
        subject.send(currency)
    }
}
