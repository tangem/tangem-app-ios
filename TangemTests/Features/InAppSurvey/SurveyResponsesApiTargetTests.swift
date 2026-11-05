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

    @Test("Submitting is a POST to the wallet's survey completions whose body carries the survey and the answer keys but not the wallet, and the logged path hides the wallet")
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
        #expect(URL(target: target).absoluteString == gatewayBase + "/wallets/\(walletId)/survey-completions")
        #expect(URL(target: target).path.hasSuffix("/api/v1/wallets/\(walletId)/survey-completions"))
        #expect(!target.requestDescription.contains(walletId))
        #expect(target.requestDescription == "/wallets/{walletId}/survey-completions")

        guard case .requestJSONEncodable(let encodable) = target.task else {
            Issue.record("Expected a JSON body, got \(target.task)")
            return
        }

        let data = try JSONEncoder().encode(encodable)
        let body = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(Set(body.keys) == ["surveyId", "answers"])
        #expect(body["surveyId"] as? String == "demand")
        #expect(body["answers"] as? [[String: String]] == [
            ["question": "goal", "answer": "buy"],
            ["question": "transaction_size", "answer": "30k_500k"],
        ])
    }

    @Test("Status is a GET of the wallet's completion of the survey, and the logged path hides the wallet")
    func statusRequestShape() throws {
        let target = TangemApiTarget(type: .surveyResponseStatus(.init(surveyId: "demand", walletId: walletId)))

        #expect(target.method == .get)
        #expect(target.validationType == .successCodes)
        #expect(target.shouldLogResponseBody == false)
        #expect(target.cachePolicy == .reloadIgnoringLocalAndRemoteCacheData)
        #expect(URL(target: target).absoluteString == gatewayBase + "/wallets/\(walletId)/survey-completions/demand")
        #expect(URL(target: target).path.hasSuffix("/api/v1/wallets/\(walletId)/survey-completions/demand"))
        #expect(!target.requestDescription.contains(walletId))
        #expect(target.requestDescription == "/wallets/{walletId}/survey-completions/demand")

        guard case .requestPlain = target.task else {
            Issue.record("Expected no query or body, got \(target.task)")
            return
        }
    }

    private var gatewayBase: String {
        AppEnvironment.current.apiBaseUrlWithGatewaySegment.absoluteString
    }
}
