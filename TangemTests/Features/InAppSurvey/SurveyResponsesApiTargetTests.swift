//
//  SurveyResponsesApiTargetTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import Moya
import TangemFoundation
@testable import Tangem

@Suite("TangemApiTarget survey responses")
struct SurveyResponsesApiTargetTests {
    private let walletId = "22BE6BE4DFC1C5D1A4F2EF6A4C1D8F4E0C2C7B3A9E2D1F0A8B7C6D5E4F3A224B"

    @Test("Submitting goes to the gateway as a POST whose body carries the survey, the wallet and the answer keys")
    func submitRequestShape() throws {
        let request = SurveyResponsesDTO.Submit.Request(
            surveyId: "demand",
            walletId: walletId,
            answers: [.init(question: "goal", answer: "buy"), .init(question: "transaction_size", answer: "30k_500k")]
        )
        let target = TangemApiTarget(type: .submitSurveyResponse(request))

        #expect(target.method == .post)
        #expect(target.validationType == .successCodes)
        #expect(target.shouldLogResponseBody == false)
        #expect(URL(target: target).absoluteString == gatewayBase + "/survey-responses")
        #expect(URL(target: target).path.hasSuffix("/api/v1/survey-responses"))

        guard case .requestJSONEncodable(let encodable) = target.task else {
            Issue.record("Expected a JSON body, got \(target.task)")
            return
        }

        let data = try JSONEncoder().encode(encodable)
        let body = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(Set(body.keys) == ["surveyId", "walletId", "answers"])
        #expect(body["surveyId"] as? String == "demand")
        #expect(body["walletId"] as? String == walletId)
        #expect(body["answers"] as? [[String: String]] == [
            ["question": "goal", "answer": "buy"],
            ["question": "transaction_size", "answer": "30k_500k"],
        ])
    }

    @Test("Status is a GET by wallet with the survey in the query, and the logged path hides the wallet")
    func statusRequestShape() throws {
        let target = TangemApiTarget(type: .surveyResponseStatus(.init(surveyId: "demand", walletId: walletId)))

        #expect(target.method == .get)
        #expect(target.validationType == .successCodes)
        #expect(target.shouldLogResponseBody == false)
        #expect(target.cachePolicy == .reloadIgnoringLocalAndRemoteCacheData)
        #expect(URL(target: target).absoluteString == gatewayBase + "/survey-responses/\(walletId)/status")
        #expect(!target.requestDescription.contains(walletId))
        #expect(target.requestDescription == "/survey-responses/{walletId}/status")

        guard case .requestParameters(let parameters, _) = target.task else {
            Issue.record("Expected query parameters, got \(target.task)")
            return
        }

        #expect(parameters as? [String: String] == ["surveyId": "demand"])
    }

    private var gatewayBase: String {
        AppEnvironment.current.apiBaseUrlWithGatewaySegment.absoluteString
    }
}
