//
//  DemandSurveyTexts.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

enum DemandSurveyTexts {
    static func question(for questionKey: String) -> String? {
        switch questionKey {
        case "goal": Localization.surveyDemandGoalQuestion
        case "transaction_size": Localization.surveyDemandTransactionSizeQuestion
        case "frequency": Localization.surveyDemandFrequencyQuestion
        case "needed_currency": Localization.surveyDemandNeededCurrencyQuestion
        case "current_solution": Localization.surveyDemandCurrentSolutionQuestion
        case "funds_owner": Localization.surveyDemandFundsOwnerQuestion
        case "business_interest": Localization.surveyDemandBusinessInterestQuestion
        default: nil
        }
    }

    static func hint(for questionKey: String) -> String? {
        switch questionKey {
        case "transaction_size": Localization.surveyDemandTransactionSizeHint
        case "needed_currency": Localization.surveyDemandNeededCurrencyHint
        default: nil
        }
    }

    static func answer(_ answerKey: String, for questionKey: String) -> String? {
        switch (questionKey, answerKey) {
        case ("goal", "buy"): Localization.surveyDemandGoalBuy
        case ("goal", "sell"): Localization.surveyDemandGoalSell
        case ("goal", "buy_sell"): Localization.surveyDemandGoalBuySell
        case ("transaction_size", "30k_500k"): Localization.surveyDemandTransactionSize30k500k
        case ("transaction_size", "500k_1m"): Localization.surveyDemandTransactionSize500k1m
        case ("transaction_size", "1m_plus"): Localization.surveyDemandTransactionSize1mPlus
        case ("frequency", "one_off"): Localization.surveyDemandFrequencyOneOff
        case ("frequency", "few_times_year"): Localization.surveyDemandFrequencyFewTimesYear
        case ("frequency", "few_times_month"): Localization.surveyDemandFrequencyFewTimesMonth
        case ("frequency", "weekly_or_more"): Localization.surveyDemandFrequencyWeeklyOrMore
        case ("needed_currency", "local"): Localization.surveyDemandNeededCurrencyLocal
        case ("needed_currency", "usd"): Localization.surveyDemandNeededCurrencyUsd
        case ("needed_currency", "eur"): Localization.surveyDemandNeededCurrencyEur
        case ("needed_currency", "other"): Localization.surveyDemandNeededCurrencyOther
        case ("current_solution", "exchange"): Localization.surveyDemandCurrentSolutionExchange
        case ("current_solution", "otc_desk"): Localization.surveyDemandCurrentSolutionOtcDesk
        case ("current_solution", "p2p"): Localization.surveyDemandCurrentSolutionP2p
        case ("current_solution", "cash_exchange"): Localization.surveyDemandCurrentSolutionCashExchange
        case ("funds_owner", "own_only"): Localization.surveyDemandFundsOwnerOwnOnly
        case ("funds_owner", "third_party"): Localization.surveyDemandFundsOwnerThirdParty
        case ("business_interest", "yes"): Localization.commonYes
        case ("business_interest", "no"): Localization.commonNo
        default: nil
        }
    }
}
