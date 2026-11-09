//
//  CommonInAppSurveyResponsesServiceTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import Testing
@testable import Tangem

@Suite("CommonInAppSurveyResponsesService")
struct CommonInAppSurveyResponsesServiceTests {
    private let userWalletId = UserWalletId(value: Data(repeating: 0xAB, count: 32))

    private var completeDemandAnswers: [String: String] {
        Dictionary(uniqueKeysWithValues: InAppSurvey.demand.questions.map { ($0.key, $0.answerKeys[0]) })
    }

    @Test("Submits every answered question in the survey's order, for the given wallet")
    func submitsAnswersInSurveyOrder() async throws {
        let apiService = FakeTangemApiService()
        let requests = OSAllocatedUnfairLock(initialState: [SurveyResponsesDTO.Submit.Request]())
        apiService.submitSurveyResponseHandler = { request in
            requests.withLock { $0.append(request) }
        }

        try await CommonInAppSurveyResponsesService(apiService: apiService).submit(
            answers: completeDemandAnswers,
            surveyId: .demand,
            userWalletId: userWalletId
        )

        let request = try #require(requests.withLock { $0 }.first)
        #expect(request.surveyId == "demand")
        #expect(request.walletId == userWalletId.stringValue)
        #expect(request.answers.map(\.question) == InAppSurvey.demand.questions.map(\.key))
        #expect(request.answers.map(\.answer) == InAppSurvey.demand.questions.map { $0.answerKeys[0] })
    }

    @Test("Unanswered optional questions are left out and the rest keeps the survey's order")
    func unansweredOptionalQuestionsAreLeftOut() async throws {
        let apiService = FakeTangemApiService()
        let requests = OSAllocatedUnfairLock(initialState: [SurveyResponsesDTO.Submit.Request]())
        apiService.submitSurveyResponseHandler = { request in
            requests.withLock { $0.append(request) }
        }
        let answers = [
            "needed_currency": "eur",
            "goal": "buy",
            "funds_owner": "third_party",
            "frequency": "one_off",
            "transaction_size": "1m_plus",
        ]

        try await CommonInAppSurveyResponsesService(apiService: apiService).submit(
            answers: answers,
            surveyId: .demand,
            userWalletId: userWalletId
        )

        let request = try #require(requests.withLock { $0 }.first)
        #expect(request.answers == [
            .init(question: "goal", answer: "buy"),
            .init(question: "transaction_size", answer: "1m_plus"),
            .init(question: "frequency", answer: "one_off"),
            .init(question: "needed_currency", answer: "eur"),
            .init(question: "funds_owner", answer: "third_party"),
        ])
    }

    @Test("A missing required, unknown or extra answer is rejected before anything is sent", arguments: InvalidAnswers.allCases)
    func invalidAnswersAreRejected(invalidAnswers: InvalidAnswers) async {
        let apiService = FakeTangemApiService()
        let callCount = OSAllocatedUnfairLock(initialState: 0)
        apiService.submitSurveyResponseHandler = { _ in
            callCount.withLock { $0 += 1 }
        }
        let answers = invalidAnswers.apply(to: completeDemandAnswers)

        await #expect(throws: InAppSurveyResponsesServiceError.invalidAnswers) {
            try await CommonInAppSurveyResponsesService(apiService: apiService).submit(answers: answers, surveyId: .demand, userWalletId: userWalletId)
        }

        #expect(callCount.withLock { $0 } == 0)
    }

    @Test("Completion comes from the backend status for the given survey and wallet", arguments: [true, false])
    func completionFollowsBackend(completed: Bool) async throws {
        let apiService = FakeTangemApiService()
        let requests = OSAllocatedUnfairLock(initialState: [SurveyResponsesDTO.Status.Request]())
        apiService.loadSurveyResponseStatusHandler = { request in
            requests.withLock { $0.append(request) }
            return .init(completed: completed)
        }

        let result = try await CommonInAppSurveyResponsesService(apiService: apiService)
            .isCompleted(surveyId: .demand, userWalletId: userWalletId)

        #expect(result == completed)
        #expect(requests.withLock { $0 } == [.init(surveyId: "demand", walletId: userWalletId.stringValue)])
    }
}

extension CommonInAppSurveyResponsesServiceTests {
    enum InvalidAnswers: CaseIterable {
        case missing
        case unknown
        case extra

        func apply(to answers: [String: String]) -> [String: String] {
            var answers = answers

            switch self {
            case .missing:
                answers.removeValue(forKey: "goal")
            case .unknown:
                answers["goal"] = "rent"
            case .extra:
                answers["favourite_color"] = "green"
            }

            return answers
        }
    }
}
