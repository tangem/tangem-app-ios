//
//  DemandSurveyViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemFoundation
import TangemLocalization
import TangemUIUtils

@MainActor
final class DemandSurveyViewModel: ObservableObject {
    @Published private(set) var answers: [String: String] = [:]
    @Published private(set) var isSubmitting = false
    @Published var alert: AlertBinder?

    let survey: InAppSurvey

    private let userWalletId: UserWalletId
    private let responsesService: InAppSurveyResponsesService
    private let sessionStore: InAppSurveySessionStore
    private let routable: DemandSurveyRoutable

    init(
        userWalletId: UserWalletId,
        routable: DemandSurveyRoutable,
        responsesService: InAppSurveyResponsesService = CommonInAppSurveyResponsesService(),
        sessionStore: InAppSurveySessionStore = InjectedValues[\.inAppSurveySessionStore],
        survey: InAppSurvey = .demand
    ) {
        self.userWalletId = userWalletId
        self.routable = routable
        self.responsesService = responsesService
        self.sessionStore = sessionStore
        self.survey = survey
    }
}

// MARK: - State

extension DemandSurveyViewModel {
    var canSubmit: Bool {
        !isSubmitting && survey.questions.filter(\.isRequired).allSatisfy { answers[$0.key] != nil }
    }

    func isSelected(_ answerKey: String, in question: InAppSurvey.Question) -> Bool {
        answers[question.key] == answerKey
    }
}

// MARK: - Actions

extension DemandSurveyViewModel {
    func select(_ answerKey: String, in question: InAppSurvey.Question) {
        guard question.answerKeys.contains(answerKey), !isSubmitting else {
            return
        }

        if answers[question.key] == answerKey, !question.isRequired {
            answers[question.key] = nil
        } else {
            answers[question.key] = answerKey
        }
    }

    func submit() {
        guard canSubmit else {
            return
        }

        isSubmitting = true

        Task { [weak self, answers, survey, userWalletId, responsesService, sessionStore] in
            do {
                try await responsesService.submit(answers: answers, surveyId: survey.id, userWalletId: userWalletId)
                sessionStore.markCompleted(surveyId: survey.id, userWalletId: userWalletId)
                self?.didSubmit()
            } catch {
                self?.didFailToSubmit()
            }
        }
    }
}

// MARK: - Private

private extension DemandSurveyViewModel {
    func didSubmit() {
        isSubmitting = false
        routable.demandSurveyDidSubmit()
    }

    func didFailToSubmit() {
        isSubmitting = false
        alert = AlertBinder(alert: Alert(
            title: Text(Localization.commonError),
            message: Text(Localization.commonSomethingWentWrong),
            primaryButton: .default(Text(Localization.commonRetry)) { [weak self] in self?.submit() },
            secondaryButton: .cancel()
        ))
    }
}

// MARK: - Routing

@MainActor
protocol DemandSurveyRoutable: AnyObject {
    func demandSurveyDidSubmit()
}
