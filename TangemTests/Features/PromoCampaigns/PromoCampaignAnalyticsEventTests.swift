//
//  PromoCampaignAnalyticsEventTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import Tangem

@Suite("PromoCampaignAnalyticsEvent")
struct PromoCampaignAnalyticsEventTests {
    private let strictCampaign = PromoCampaignFixtures.makeCampaign(id: 42)
    private let linkedPayoutCampaign = PromoCampaignFixtures.makeCampaign(id: 42, isPayoutNeeded: true, matchMode: .linkedWallet)

    @Test("The campaign sheet reports the campaign as its screen, with the match mode and whether it pays out")
    func screenOpened() {
        let event = PromoCampaignAnalyticsEvent.screenOpened(campaign: linkedPayoutCampaign)

        #expect(event.event == .promotionScreenOpened)
        #expect(event.params == [
            .screen: "campaign_42",
            .campaign: "campaign_42",
            .matchMode: "Linked Wallet",
            .payout: "Yes",
        ])
        #expect(PromoCampaignAnalyticsEvent.screenOpened(campaign: strictCampaign).params[.matchMode] == "Strict")
        #expect(PromoCampaignAnalyticsEvent.screenOpened(campaign: strictCampaign).params[.payout] == "No")
    }

    @Test("The already-enrolled screen tells the entry sheet from the enrollment response", arguments: [
        (PromoCampaignAnalyticsEvent.AlreadyEnrolledSource.entry, "Entry"),
        (.enrollResponse, "Enroll Response"),
    ])
    func alreadyEnrolledScreenOpened(source: PromoCampaignAnalyticsEvent.AlreadyEnrolledSource, value: String) {
        let event = PromoCampaignAnalyticsEvent.alreadyEnrolledScreenOpened(campaign: strictCampaign, source: source)

        #expect(event.event == .promotionAlreadyEnrolledScreenOpened)
        #expect(event.params == [.campaign: "campaign_42", .source: value])
    }

    @Test("The enroll tap carries the payout token and the number of wallets sent")
    func enrollButtonClickedWithPayout() {
        let event = PromoCampaignAnalyticsEvent.enrollButtonClicked(
            campaign: linkedPayoutCampaign,
            payoutToken: CampaignsFixtures.usdcOnEthereum,
            walletsCount: 3
        )

        #expect(event.event == .promotionEnrollButtonClicked)
        #expect(event.params == [
            .campaign: "campaign_42",
            .matchMode: "Linked Wallet",
            .walletsCount: "3",
            .token: "USDC",
            .blockchain: "Ethereum",
        ])
    }

    @Test("Without a payout the enroll events carry no token and no blockchain")
    func enrollEventsWithoutPayout() {
        let clicked = PromoCampaignAnalyticsEvent.enrollButtonClicked(campaign: strictCampaign, payoutToken: nil, walletsCount: 1)
        let successful = PromoCampaignAnalyticsEvent.enrollSuccessful(campaign: strictCampaign, payoutToken: nil, walletsEnrolled: 1, walletsTotal: 1)

        #expect(clicked.params[.token] == nil)
        #expect(clicked.params[.blockchain] == nil)
        #expect(successful.params[.token] == nil)
        #expect(successful.params[.blockchain] == nil)
    }

    @Test("A successful enrollment reports how many wallets of the answer got enrolled")
    func enrollSuccessful() {
        let event = PromoCampaignAnalyticsEvent.enrollSuccessful(
            campaign: linkedPayoutCampaign,
            payoutToken: CampaignsFixtures.usdcOnEthereum,
            walletsEnrolled: 1,
            walletsTotal: 2
        )

        #expect(event.event == .promotionEnrollSuccessful)
        #expect(event.params == [
            .campaign: "campaign_42",
            .matchMode: "Linked Wallet",
            .walletsEnrolled: "1",
            .walletsTotal: "2",
            .token: "USDC",
            .blockchain: "Ethereum",
        ])
    }

    @Test("A failed enrollment reports its reason and the status code", arguments: [
        (PromoCampaignAnalyticsEvent.EnrollErrorReason.unavailable, "Unavailable"),
        (.notActiveYet, "Not Active Yet"),
        (.technical, "Technical"),
    ])
    func enrollError(reason: PromoCampaignAnalyticsEvent.EnrollErrorReason, value: String) {
        let event = PromoCampaignAnalyticsEvent.enrollError(campaign: strictCampaign, reason: reason, statusCode: 404)

        #expect(event.event == .promotionEnrollError)
        #expect(event.params == [.campaign: "campaign_42", .reason: value, .errorCode: "404"])
    }

    @Test("A failed enrollment without a status code leaves the error code out")
    func enrollErrorWithoutStatusCode() {
        let event = PromoCampaignAnalyticsEvent.enrollError(campaign: strictCampaign, reason: .technical, statusCode: nil)

        #expect(event.params[.errorCode] == nil)
    }
}
