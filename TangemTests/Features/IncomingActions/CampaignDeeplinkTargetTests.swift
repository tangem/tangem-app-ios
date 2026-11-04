//
//  CampaignDeeplinkTargetTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import Testing
@testable import Tangem

@Suite("Campaign deeplink target")
struct CampaignDeeplinkTargetTests {
    @Test("A numeric id opens the promo campaign for the selected wallet")
    func numericIdOpensPromoCampaign() {
        let target = CampaignDeeplinkTarget(
            deeplink: CampaignsDeeplink(campaignId: "5"),
            selectedUserWalletId: Constants.userWalletId
        )

        #expect(target == .promoCampaign(campaignId: 5, userWalletId: Constants.userWalletId))
    }

    @Test(
        "An id that is not a plain number opens the cashback campaign",
        arguments: ["whale-swap-cashback", "reactivation-cashback", "-1", "+5", "5a", " 5"]
    )
    func nonNumericIdOpensCashbackCampaign(campaignId: String) {
        let target = CampaignDeeplinkTarget(
            deeplink: CampaignsDeeplink(campaignId: campaignId),
            selectedUserWalletId: Constants.userWalletId
        )

        #expect(target == .cashbackCampaign(campaignId: campaignId))
    }

    @Test("A link without an id opens the cashback campaign")
    func missingIdOpensCashbackCampaign() {
        let target = CampaignDeeplinkTarget(
            deeplink: CampaignsDeeplink(campaignId: nil),
            selectedUserWalletId: Constants.userWalletId
        )

        #expect(target == .cashbackCampaign(campaignId: nil))
    }

    @Test("A numeric id with no wallet selected falls back to the cashback campaign")
    func numericIdWithoutWalletOpensCashbackCampaign() {
        let target = CampaignDeeplinkTarget(
            deeplink: CampaignsDeeplink(campaignId: "5"),
            selectedUserWalletId: nil
        )

        #expect(target == .cashbackCampaign(campaignId: "5"))
    }
}

// MARK: - Constants

private extension CampaignDeeplinkTargetTests {
    enum Constants {
        static let userWalletId = UserWalletId(value: Data([0xAA]))
    }
}
