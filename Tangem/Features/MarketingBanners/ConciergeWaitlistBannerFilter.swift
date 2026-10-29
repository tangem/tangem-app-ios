//
//  ConciergeWaitlistBannerFilter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class ConciergeWaitlistBannerFilter {
    private let userWalletId: UserWalletId
    private let responsesService: InAppSurveyResponsesService
    private let sessionStore: InAppSurveySessionStore
    private let surveyId: InAppSurveyId = .demand

    private let isStatusRequested = OSAllocatedUnfairLock(initialState: false)

    init(
        userWalletId: UserWalletId,
        responsesService: InAppSurveyResponsesService = CommonInAppSurveyResponsesService(),
        sessionStore: InAppSurveySessionStore = InjectedValues[\.inAppSurveySessionStore]
    ) {
        self.userWalletId = userWalletId
        self.responsesService = responsesService
        self.sessionStore = sessionStore
    }

    func filter(_ banners: AnyPublisher<[CallToActionMarketingBanner], Never>) -> AnyPublisher<[CallToActionMarketingBanner], Never> {
        banners
            .combineLatest(sessionStore.isCompletedPublisher(surveyId: surveyId, userWalletId: userWalletId))
            .handleEvents(receiveOutput: { [weak self] banners, isCompleted in
                if !isCompleted, banners.contains(where: Self.isConciergeWaitlist) {
                    self?.requestStatusIfNeeded()
                }
            })
            .map { banners, isCompleted in
                isCompleted ? banners.filter { !Self.isConciergeWaitlist($0) } : banners
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension ConciergeWaitlistBannerFilter {
    static func isConciergeWaitlist(_ banner: CallToActionMarketingBanner) -> Bool {
        ConciergeWaitlistLink.matches(banner.link)
    }

    func requestStatusIfNeeded() {
        let shouldRequest = isStatusRequested.withLock { isRequested in
            defer { isRequested = true }
            return !isRequested
        }

        guard shouldRequest else {
            return
        }

        Task { @MainActor [responsesService, sessionStore, surveyId, userWalletId] in
            let isCompleted = (try? await responsesService.isCompleted(surveyId: surveyId, userWalletId: userWalletId)) ?? false

            if isCompleted {
                sessionStore.markCompleted(surveyId: surveyId, userWalletId: userWalletId)
            }
        }
    }
}
