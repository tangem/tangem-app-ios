//
//  DemandSurveyViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import Testing
@testable import Tangem

@MainActor
@Suite("DemandSurveyViewModel", .timeLimit(.minutes(1)))
struct DemandSurveyViewModelTests {
    private let userWalletId = UserWalletId(value: Data(repeating: 0xAB, count: 32))

    private var requiredQuestions: [InAppSurvey.Question] {
        InAppSurvey.demand.questions.filter(\.isRequired)
    }

    private var optionalQuestion: InAppSurvey.Question {
        InAppSurvey.demand.questions.first { !$0.isRequired }!
    }

    private func makeViewModel(
        service: InAppSurveyResponsesServiceStub = InAppSurveyResponsesServiceStub(),
        routable: DemandSurveyRoutableSpy? = nil,
        sessionStore: InAppSurveySessionStore = CommonInAppSurveySessionStore()
    ) -> DemandSurveyViewModel {
        DemandSurveyViewModel(
            userWalletId: userWalletId,
            routable: routable ?? DemandSurveyRoutableSpy(),
            responsesService: service,
            sessionStore: sessionStore
        )
    }

    private func answerRequiredQuestions(in viewModel: DemandSurveyViewModel) {
        for question in requiredQuestions {
            viewModel.select(question.answerKeys[0], in: question)
        }
    }

    @Test("Nothing is selected at first and the button waits for every required answer")
    func submitNeedsEveryRequiredAnswer() {
        let viewModel = makeViewModel()

        #expect(viewModel.answers.isEmpty)
        #expect(!viewModel.canSubmit)

        for question in requiredQuestions.dropLast() {
            viewModel.select(question.answerKeys[0], in: question)
        }

        #expect(!viewModel.canSubmit)

        let lastQuestion = requiredQuestions.last!
        viewModel.select(lastQuestion.answerKeys[0], in: lastQuestion)

        #expect(viewModel.canSubmit)
    }

    @Test("A question keeps one answer, and picking another replaces it")
    func singleChoicePerQuestion() {
        let viewModel = makeViewModel()
        let question = requiredQuestions[0]

        viewModel.select(question.answerKeys[0], in: question)
        viewModel.select(question.answerKeys[1], in: question)

        #expect(viewModel.answers == [question.key: question.answerKeys[1]])
        #expect(viewModel.isSelected(question.answerKeys[1], in: question))
        #expect(!viewModel.isSelected(question.answerKeys[0], in: question))
    }

    @Test("Tapping the chosen answer clears an optional question but keeps a required one")
    func tappingTheChosenAnswerAgain() {
        let viewModel = makeViewModel()
        let required = requiredQuestions[0]

        viewModel.select(required.answerKeys[0], in: required)
        viewModel.select(required.answerKeys[0], in: required)
        viewModel.select(optionalQuestion.answerKeys[0], in: optionalQuestion)
        viewModel.select(optionalQuestion.answerKeys[0], in: optionalQuestion)

        #expect(viewModel.answers == [required.key: required.answerKeys[0]])
    }

    @Test("An answer the question doesn't offer is ignored")
    func unknownAnswerIsIgnored() {
        let viewModel = makeViewModel()

        viewModel.select("rent", in: requiredQuestions[0])

        #expect(viewModel.answers.isEmpty)
    }

    @Test("A successful submit sends the answers for the wallet, records the completion and moves on")
    func successfulSubmit() async {
        let service = InAppSurveyResponsesServiceStub()
        let routable = DemandSurveyRoutableSpy()
        let sessionStore = CommonInAppSurveySessionStore()
        let viewModel = makeViewModel(service: service, routable: routable, sessionStore: sessionStore)
        answerRequiredQuestions(in: viewModel)
        let expectedAnswers = viewModel.answers

        viewModel.submit()
        await routable.waitForSubmit()

        #expect(service.submissions == [.init(answers: expectedAnswers, surveyId: .demand, userWalletId: userWalletId)])
        #expect(await sessionStore.isCompletedPublisher(surveyId: .demand, userWalletId: userWalletId).values.first { _ in true } == true)
        #expect(!viewModel.isSubmitting)
    }

    @Test("A failed submit shows an error and keeps the answers for a retry")
    func failedSubmit() async {
        let service = InAppSurveyResponsesServiceStub(submitResult: .failure(InAppSurveyResponsesServiceStub.StubError.failed))
        let routable = DemandSurveyRoutableSpy()
        let viewModel = makeViewModel(service: service, routable: routable)
        answerRequiredQuestions(in: viewModel)
        let answers = viewModel.answers

        viewModel.submit()
        _ = await viewModel.$alert.values.first { $0 != nil }

        #expect(viewModel.answers == answers)
        #expect(viewModel.canSubmit)
        #expect(routable.submitCount == 0)

        service.setSubmitResult(.success(()))
        viewModel.submit()
        await routable.waitForSubmit()

        #expect(service.submissions.count == 2)
    }
}

// MARK: - Spy

@MainActor
final class DemandSurveyRoutableSpy: DemandSurveyRoutable {
    private(set) var submitCount = 0
    private let submits: AsyncStream<Void>
    private let continuation: AsyncStream<Void>.Continuation

    init() {
        (submits, continuation) = AsyncStream<Void>.makeStream()
    }

    func demandSurveyDidSubmit() {
        submitCount += 1
        continuation.yield()
    }

    func waitForSubmit() async {
        var iterator = submits.makeAsyncIterator()
        _ = await iterator.next()
    }
}
