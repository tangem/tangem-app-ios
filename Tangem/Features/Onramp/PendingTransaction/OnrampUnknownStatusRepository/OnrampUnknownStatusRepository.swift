//
//  OnrampUnknownStatusRepository.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol OnrampUnknownStatusRepository: AnyObject {
    func markUnknown(_ record: OnrampUnknownStatusRecord)

    func activeRecords(
        userWalletId: String,
        toContractAddress: String,
        toNetwork: String
    ) -> [OnrampUnknownStatusRecord]

    func markAttempted(recordId: String)

    func clear(recordId: String)
}

enum OnrampUnknownStatusRepositoryConstants {
    static let ttl: TimeInterval = 15 * 60
    static let recoveryThrottle: TimeInterval = 30
}

private struct OnrampUnknownStatusRepositoryKey: InjectionKey {
    static var currentValue: OnrampUnknownStatusRepository = CommonOnrampUnknownStatusRepository()
}

extension InjectedValues {
    var onrampUnknownStatusRepository: OnrampUnknownStatusRepository {
        get { Self[OnrampUnknownStatusRepositoryKey.self] }
        set { Self[OnrampUnknownStatusRepositoryKey.self] = newValue }
    }
}
