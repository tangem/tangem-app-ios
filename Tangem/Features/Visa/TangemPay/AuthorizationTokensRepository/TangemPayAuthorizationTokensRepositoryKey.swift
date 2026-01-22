//
//  TangemPayAuthorizationTokensRepositoryKey.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemVisa
import TangemPay

private struct TangemPayAuthorizationTokensRepositoryKey: InjectionKey {
    static var currentValue: TangemPayAuthorizationTokensRepository = CommonTangemPayAuthorizationTokensRepository()
}

extension InjectedValues {
    var tangemPayAuthorizationTokensRepository: TangemPayAuthorizationTokensRepository {
        get { Self[TangemPayAuthorizationTokensRepositoryKey.self] }
        set { Self[TangemPayAuthorizationTokensRepositoryKey.self] = newValue }
    }
}
