//
//  PromoCampaignAnalyticsEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum PromoCampaignAnalyticsEvent: Equatable {
    case screenOpened(campaign: PromoCampaign)
    case alreadyEnrolledScreenOpened(campaign: PromoCampaign, source: AlreadyEnrolledSource)
    case enrollButtonClicked(campaign: PromoCampaign, payoutToken: TokenItem?, walletsCount: Int)
    case enrollSuccessful(campaign: PromoCampaign, payoutToken: TokenItem?, walletsEnrolled: Int, walletsTotal: Int)
    case enrollError(campaign: PromoCampaign, reason: EnrollErrorReason, statusCode: Int?)

    var event: Analytics.Event {
        switch self {
        case .screenOpened: .promotionScreenOpened
        case .alreadyEnrolledScreenOpened: .promotionAlreadyEnrolledScreenOpened
        case .enrollButtonClicked: .promotionEnrollButtonClicked
        case .enrollSuccessful: .promotionEnrollSuccessful
        case .enrollError: .promotionEnrollError
        }
    }

    var params: [Analytics.ParameterKey: String] {
        switch self {
        case .screenOpened(let campaign):
            return [
                .screen: campaign.name,
                .campaign: campaign.name,
                .matchMode: matchModeValue(campaign.matchMode).rawValue,
                .payout: Analytics.ParameterValue.affirmativeOrNegative(for: campaign.isPayoutNeeded).rawValue,
            ]
        case .alreadyEnrolledScreenOpened(let campaign, let source):
            return [
                .campaign: campaign.name,
                .source: sourceValue(source).rawValue,
            ]
        case .enrollButtonClicked(let campaign, let payoutToken, let walletsCount):
            return [
                .campaign: campaign.name,
                .matchMode: matchModeValue(campaign.matchMode).rawValue,
                .walletsCount: String(walletsCount),
            ].merging(tokenParams(payoutToken)) { current, _ in current }
        case .enrollSuccessful(let campaign, let payoutToken, let walletsEnrolled, let walletsTotal):
            return [
                .campaign: campaign.name,
                .matchMode: matchModeValue(campaign.matchMode).rawValue,
                .walletsEnrolled: String(walletsEnrolled),
                .walletsTotal: String(walletsTotal),
            ].merging(tokenParams(payoutToken)) { current, _ in current }
        case .enrollError(let campaign, let reason, let statusCode):
            var params: [Analytics.ParameterKey: String] = [
                .campaign: campaign.name,
                .reason: reasonValue(reason).rawValue,
            ]
            params[.errorCode] = statusCode.map(String.init)
            return params
        }
    }
}

// MARK: - Auxiliary types

extension PromoCampaignAnalyticsEvent {
    enum AlreadyEnrolledSource: Equatable {
        case entry
        case enrollResponse
    }

    enum EnrollErrorReason: Equatable {
        case unavailable
        case notActiveYet
        case technical
    }
}

// MARK: - Private

private extension PromoCampaignAnalyticsEvent {
    func matchModeValue(_ matchMode: PromoCampaign.MatchMode) -> Analytics.ParameterValue {
        switch matchMode {
        case .strict: .strict
        case .linkedWallet: .linkedWallet
        }
    }

    func sourceValue(_ source: AlreadyEnrolledSource) -> Analytics.ParameterValue {
        switch source {
        case .entry: .entry
        case .enrollResponse: .enrollResponse
        }
    }

    func reasonValue(_ reason: EnrollErrorReason) -> Analytics.ParameterValue {
        switch reason {
        case .unavailable: .unavailable
        case .notActiveYet: .notActiveYet
        case .technical: .technical
        }
    }

    func tokenParams(_ tokenItem: TokenItem?) -> [Analytics.ParameterKey: String] {
        tokenItem?.campaignAnalyticsParams ?? [:]
    }
}
