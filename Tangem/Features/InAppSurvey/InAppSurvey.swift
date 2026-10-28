//
//  InAppSurvey.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum InAppSurveyId: String, CaseIterable {
    case demand
}

struct InAppSurvey: Equatable {
    let id: InAppSurveyId
    let questions: [Question]

    struct Question: Equatable {
        let key: String
        let answerKeys: [String]
        let isRequired: Bool
    }
}

extension InAppSurveyId {
    var survey: InAppSurvey {
        switch self {
        case .demand:
            .demand
        }
    }
}

extension InAppSurvey {
    static let demand = InAppSurvey(
        id: .demand,
        questions: [
            Question(key: "goal", answerKeys: ["buy", "sell", "buy_sell"], isRequired: true),
            Question(key: "transaction_size", answerKeys: ["30k_500k", "500k_1m", "1m_plus"], isRequired: true),
            Question(key: "frequency", answerKeys: ["one_off", "few_times_year", "few_times_month", "weekly_or_more"], isRequired: true),
            Question(key: "needed_currency", answerKeys: ["local", "usd", "eur", "other"], isRequired: true),
            Question(key: "current_solution", answerKeys: ["exchange", "otc_desk", "p2p", "cash_exchange"], isRequired: false),
            Question(key: "funds_owner", answerKeys: ["own_only", "third_party"], isRequired: false),
            Question(key: "business_interest", answerKeys: ["yes", "no"], isRequired: false),
        ]
    )
}
