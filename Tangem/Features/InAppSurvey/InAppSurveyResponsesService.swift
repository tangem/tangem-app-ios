//
//  InAppSurveyResponsesService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

protocol InAppSurveyResponsesService {
    func submit(answers: [String: String], surveyId: InAppSurveyId, userWalletId: UserWalletId) async throws
    func isCompleted(surveyId: InAppSurveyId, userWalletId: UserWalletId) async throws -> Bool
}

enum InAppSurveyResponsesServiceError: Error, Equatable {
    case invalidAnswers
}

final class CommonInAppSurveyResponsesService {
    private let apiService: TangemApiService

    init(apiService: TangemApiService = InjectedValues[\.tangemApiService]) {
        self.apiService = apiService
    }
}

// MARK: - InAppSurveyResponsesService

extension CommonInAppSurveyResponsesService: InAppSurveyResponsesService {
    func submit(answers: [String: String], surveyId: InAppSurveyId, userWalletId: UserWalletId) async throws {
        let survey = surveyId.survey

        let orderedAnswers = try survey.questions.compactMap { question -> SurveyResponsesDTO.Submit.Answer? in
            guard let answer = answers[question.key] else {
                if question.isRequired {
                    throw InAppSurveyResponsesServiceError.invalidAnswers
                }

                return nil
            }

            guard question.answerKeys.contains(answer) else {
                throw InAppSurveyResponsesServiceError.invalidAnswers
            }

            return SurveyResponsesDTO.Submit.Answer(question: question.key, answer: answer)
        }

        guard orderedAnswers.count == answers.count else {
            throw InAppSurveyResponsesServiceError.invalidAnswers
        }

        let request = SurveyResponsesDTO.Submit.Request(
            surveyId: surveyId.rawValue,
            walletId: userWalletId.stringValue,
            answers: orderedAnswers
        )

        try await apiService.submitSurveyResponse(request: request)
    }

    func isCompleted(surveyId: InAppSurveyId, userWalletId: UserWalletId) async throws -> Bool {
        let request = SurveyResponsesDTO.Status.Request(
            surveyId: surveyId.rawValue,
            walletId: userWalletId.stringValue
        )

        return try await apiService.loadSurveyResponseStatus(request: request).completed
    }
}
