//
//  InAppSurveyResponsesServiceStub.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
@testable import Tangem

final class InAppSurveyResponsesServiceStub: InAppSurveyResponsesService {
    struct Submission: Equatable {
        let answers: [String: String]
        let surveyId: InAppSurveyId
        let userWalletId: UserWalletId
    }

    enum StubError: Error {
        case failed
    }

    private let state: OSAllocatedUnfairLock<State>

    init(submitResult: Result<Void, Error> = .success(()), completionResult: Result<Bool, Error> = .success(false)) {
        state = OSAllocatedUnfairLock(initialState: State(submitResult: submitResult, completionResult: completionResult))
    }

    var submissions: [Submission] {
        state.withLock { $0.submissions }
    }

    var statusRequestCount: Int {
        state.withLock { $0.statusRequestCount }
    }

    func setSubmitResult(_ result: Result<Void, Error>) {
        state.withLock { $0.submitResult = result }
    }

    func submit(answers: [String: String], surveyId: InAppSurveyId, userWalletId: UserWalletId) async throws {
        let result = state.withLock { state in
            state.submissions.append(Submission(answers: answers, surveyId: surveyId, userWalletId: userWalletId))
            return state.submitResult
        }

        try result.get()
    }

    func isCompleted(surveyId: InAppSurveyId, userWalletId: UserWalletId) async throws -> Bool {
        let result = state.withLock { state in
            state.statusRequestCount += 1
            return state.completionResult
        }

        return try result.get()
    }
}

private extension InAppSurveyResponsesServiceStub {
    struct State {
        var submitResult: Result<Void, Error>
        var completionResult: Result<Bool, Error>
        var submissions: [Submission] = []
        var statusRequestCount = 0
    }
}
