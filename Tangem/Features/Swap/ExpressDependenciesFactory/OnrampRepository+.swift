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

extension InjectedValues {
    var onrampRepository: OnrampRepository {
        get { Self[OnrampRepositoryKey.self] }
        set { Self[OnrampRepositoryKey.self] = newValue }
    }
}
