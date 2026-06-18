//
//  OnrampUnknownStatusRepository.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation

protocol OnrampUnknownStatusRepository: AnyObject {
    var recordsPublisher: AnyPublisher<[OnrampUnknownStatusRecord], Never> { get }

    func track(_ record: OnrampUnknownStatusRecord)

    func pendingRecoveryCandidates(
        userWalletId: String,
        toContractAddress: String,
        toNetwork: String
    ) -> [OnrampUnknownStatusRecord]

    func noteRecoveryProbe(recordId: String)

    func untrack(recordId: String)
}

enum OnrampUnknownStatusRepositoryConstants {
    static let ttl: TimeInterval = 15 * 60
    static let recoveryThrottle: TimeInterval = 30
    static let historyPageLimit = 5
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
