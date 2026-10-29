//
//  DemandSurveyTextsTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("DemandSurveyTexts")
struct DemandSurveyTextsTests {
    @Test("Every question and answer in the catalogue has a text to show")
    func everyKeyHasText() {
        for question in InAppSurvey.demand.questions {
            #expect(DemandSurveyTexts.question(for: question.key) != nil, "No text for question \(question.key)")

            for answerKey in question.answerKeys {
                #expect(DemandSurveyTexts.answer(answerKey, for: question.key) != nil, "No text for \(question.key).\(answerKey)")
            }
        }
    }
}
