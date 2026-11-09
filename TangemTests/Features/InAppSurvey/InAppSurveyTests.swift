//
//  InAppSurveyTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("InAppSurvey")
struct InAppSurveyTests {
    @Test("The demand survey sends exactly the keys agreed with the backend and Android, in their fixed order")
    func demandSurveyKeys() {
        let keys = InAppSurvey.demand.questions.map { [$0.key] + $0.answerKeys }

        #expect(keys == [
            ["goal", "buy", "sell", "buy_sell"],
            ["transaction_size", "30k_500k", "500k_1m", "1m_plus"],
            ["frequency", "one_off", "few_times_year", "few_times_month", "weekly_or_more"],
            ["needed_currency", "local", "usd", "eur", "other"],
            ["current_solution", "exchange", "otc_desk", "p2p", "cash_exchange"],
            ["funds_owner", "own_only", "third_party"],
            ["business_interest", "yes", "no"],
        ])
    }

    @Test("Only the first four demand questions are required")
    func demandRequiredQuestions() {
        #expect(InAppSurvey.demand.questions.map(\.isRequired) == [true, true, true, true, false, false, false])
    }

    @Test("Every key matches the backend's format", arguments: InAppSurveyId.allCases)
    func keysMatchBackendFormat(id: InAppSurveyId) {
        let survey = id.survey
        let keys = survey.questions.flatMap { [$0.key] + $0.answerKeys }

        #expect(id.rawValue.wholeMatch(of: #/[a-z0-9_]{1,32}/#) != nil)
        #expect(keys.allSatisfy { $0.wholeMatch(of: #/[a-z0-9_]{1,64}/#) != nil })
        #expect(Set(survey.questions.map(\.key)).count == survey.questions.count)
        #expect(survey.id == id)
    }
}
