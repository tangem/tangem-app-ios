//
//  LegacyRateAppService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol LegacyRateAppService: AnyObject {
    var shouldShowRateAppWarning: Bool { get }
    var shouldCheckBalanceForRateApp: Bool { get }
    func registerPositiveBalanceDate()
    func dismissRateAppWarning()
    func userReactToRateAppWarning(isPositive: Bool)
}

private struct RateAppServiceKey: InjectionKey {
    static var currentValue: LegacyRateAppService = CommonLegacyRateAppService()
}

extension InjectedValues {
    var rateAppService: LegacyRateAppService {
        get { Self[RateAppServiceKey.self] }
        set { Self[RateAppServiceKey.self] = newValue }
    }
}
