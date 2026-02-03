//
//  ReferralAnalyticsHelper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

final class ReferralAnalyticsHelper {
    @Injected(\.referralService) private var referralService: ReferralService

    func getReferralParams() -> [Analytics.ParameterKey: String] {
        guard let refcode = referralService.refcode else {
            return [
                .referral: Analytics.ParameterValue.false.rawValue,
                .referralID: Analytics.ParameterValue.empty.rawValue,
            ]
        }

        return [
            .referral: Analytics.ParameterValue.true.rawValue,
            .referralID: refcode,
        ]
    }
}
