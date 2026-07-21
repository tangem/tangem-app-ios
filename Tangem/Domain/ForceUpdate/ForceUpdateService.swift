//
//  ForceUpdateService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol ForceUpdateService: AnyObject {
    var state: ForceUpdateState { get }
    var statePublisher: AnyPublisher<ForceUpdateState, Never> { get }

    var startupBlockingReason: ForceUpdateReason? { get }

    func refreshCache()
    func refreshAndApply()
    func dismissOSUpdateWarning()
}

private struct ForceUpdateServiceKey: InjectionKey {
    static var currentValue: ForceUpdateService = CommonForceUpdateService(
        cache: DefaultForceUpdateCache(
            storage: UserDefaultsBlockchainDataStorage(),
            ttl: Constants.cacheTTL,
            now: { Date() }
        )
    )
}

private enum Constants {
    /// The cached backend response is considered stale after this interval.
    static let cacheTTL: TimeInterval = 24 * 60 * 60
}

extension InjectedValues {
    var forceUpdateService: ForceUpdateService {
        get { Self[ForceUpdateServiceKey.self] }
        set { Self[ForceUpdateServiceKey.self] = newValue }
    }
}
