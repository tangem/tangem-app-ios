//
//  ReferralService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol ReferralService {
    var refcode: String? { get }
    var campaign: String? { get }
    var hasNoReferral: Bool { get }

    func saveReferralIfNeeded(refcode: String, campaign: String?)
    func saveAndBindIfNeeded(refcode: String, campaign: String?)
    func retryBindingIfNeeded()
}

private struct ReferralServiceKey: InjectionKey {
    static var currentValue: ReferralService = CommonReferralService()
}

extension InjectedValues {
    var referralService: ReferralService {
        get { Self[ReferralServiceKey.self] }
        set { Self[ReferralServiceKey.self] = newValue }
    }
}
