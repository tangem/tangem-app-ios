//
//  OnrampRepository+.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress

private struct OnrampRepositoryKey: InjectionKey {
    static var currentValue: OnrampRepository = TangemExpressFactory().makeOnrampRepository(
        storage: CommonOnrampStorage()
    )
}

private struct OnrampUserCurrencyStoreKey: InjectionKey {
    static var currentValue = OnrampUserCurrencyStore(storage: CommonOnrampStorage(key: .onrampUserCurrency))
}

extension InjectedValues {
    var onrampRepository: OnrampRepository {
        get { Self[OnrampRepositoryKey.self] }
        set { Self[OnrampRepositoryKey.self] = newValue }
    }

    var onrampUserCurrencyStore: OnrampUserCurrencyStore {
        get { Self[OnrampUserCurrencyStoreKey.self] }
        set { Self[OnrampUserCurrencyStoreKey.self] = newValue }
    }
}
