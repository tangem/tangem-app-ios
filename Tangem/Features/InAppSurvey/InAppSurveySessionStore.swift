//
//  InAppSurveySessionStore.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

protocol InAppSurveySessionStore: AnyObject {
    func markCompleted(surveyId: InAppSurveyId, userWalletId: UserWalletId)
    func isCompletedPublisher(surveyId: InAppSurveyId, userWalletId: UserWalletId) -> AnyPublisher<Bool, Never>
}

final class CommonInAppSurveySessionStore {
    private let completionsState = OSAllocatedUnfairLock(initialState: Set<Completion>())
    private let completionsSubject = CurrentValueSubject<Set<Completion>, Never>([])
}

// MARK: - InAppSurveySessionStore

extension CommonInAppSurveySessionStore: InAppSurveySessionStore {
    func markCompleted(surveyId: InAppSurveyId, userWalletId: UserWalletId) {
        let completions = completionsState.withLock { completions in
            completions.insert(Completion(surveyId: surveyId, userWalletId: userWalletId))
            return completions
        }

        completionsSubject.send(completions)
    }

    func isCompletedPublisher(surveyId: InAppSurveyId, userWalletId: UserWalletId) -> AnyPublisher<Bool, Never> {
        let completion = Completion(surveyId: surveyId, userWalletId: userWalletId)

        return completionsSubject
            .map { $0.contains(completion) }
            .scan(false) { $0 || $1 }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}

// MARK: - Types

private extension CommonInAppSurveySessionStore {
    struct Completion: Hashable {
        let surveyId: InAppSurveyId
        let userWalletId: UserWalletId
    }
}

// MARK: - Injection

private struct InAppSurveySessionStoreKey: InjectionKey {
    static var currentValue: InAppSurveySessionStore = CommonInAppSurveySessionStore()
}

extension InjectedValues {
    var inAppSurveySessionStore: InAppSurveySessionStore {
        get { Self[InAppSurveySessionStoreKey.self] }
        set { Self[InAppSurveySessionStoreKey.self] = newValue }
    }
}
