//
//  TransactionHistoryAuxDataRepository+Injected.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

extension InjectedValues {
    var transactionHistoryAuxDataRepository: TransactionHistoryAuxDataRepository {
        get { Self[TransactionHistoryAuxDataRepositoryKey.self] }
        set { Self[TransactionHistoryAuxDataRepositoryKey.self] = newValue }
    }
}

// MARK: - Private implementation

private struct TransactionHistoryAuxDataRepositoryKey: InjectionKey {
    static var currentValue: TransactionHistoryAuxDataRepository = CommonTransactionHistoryAuxDataRepository(
        cachingExpressAPIProviderFactory: CachingExpressAPIProviderFactory { userWalletId, refcode in
            ExpressAPIProviderFactory().makeExpressAPIProvider(userId: userWalletId, refcode: refcode)
        },
        storage: UserDefaultsTransactionHistoryAuxDataStorage(suiteName: AppEnvironment.current.suiteName)
    )
}
