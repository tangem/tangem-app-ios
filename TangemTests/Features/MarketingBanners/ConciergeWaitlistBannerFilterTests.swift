//
//  ConciergeWaitlistBannerFilterTests.swift
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

@Suite("ConciergeWaitlistBannerFilter", .tags(.marketingBanners), .timeLimit(.minutes(1)))
struct ConciergeWaitlistBannerFilterTests {
    private let userWalletId = UserWalletId(value: Data(repeating: 0xAB, count: 32))
    private let waitlist = Self.banner(id: 1, link: "tangem://onramp?type=concierge_waitlist")
    private let partner = Self.banner(id: 2, link: "https://partner.example.com/otc")

    private static func banner(id: Int, link: String) -> CallToActionMarketingBanner {
        .standalone(CallToActionMarketingBannerViewModel(
            id: id,
            title: "Title",
            buttonTitle: "Button",
            isGlowing: false,
            link: URL(string: link)!,
            isDismissible: false,
            content: .init(subtitle: nil, iconURL: nil)
        ))
    }

    private func makeOutput(
        service: InAppSurveyResponsesServiceStub,
        sessionStore: InAppSurveySessionStore = CommonInAppSurveySessionStore(),
        banners: CurrentValueSubject<[CallToActionMarketingBanner], Never>
    ) -> (ConciergeWaitlistBannerFilter, AsyncPublisher<AnyPublisher<[CallToActionMarketingBanner], Never>>) {
        let filter = ConciergeWaitlistBannerFilter(userWalletId: userWalletId, responsesService: service, sessionStore: sessionStore)
        let output = filter.filter(banners.eraseToAnyPublisher())
            .buffer(size: 16, prefetch: .keepFull, whenFull: .dropOldest)
            .eraseToAnyPublisher()
        return (filter, output.values)
    }

    @Test("The Waitlist banner stays until the backend says the survey is done, then only it goes")
    func backendCompletionHidesWaitlist() async {
        let service = InAppSurveyResponsesServiceStub(completionResult: .success(true))
        let banners = CurrentValueSubject<[CallToActionMarketingBanner], Never>([waitlist, partner])
        let (filter, output) = makeOutput(service: service, banners: banners)
        var iterator = output.makeAsyncIterator()

        #expect(await iterator.next() == [waitlist, partner])
        #expect(await iterator.next() == [partner])
        withExtendedLifetime(filter) {}
    }

    @Test("A failed status request leaves the Waitlist banner in place")
    func failedStatusKeepsWaitlist() async {
        let service = InAppSurveyResponsesServiceStub(completionResult: .failure(InAppSurveyResponsesServiceStub.StubError.failed))
        await expectWaitlistKept(service: service)
        #expect(service.statusRequestCount == 1)
    }

    @Test("The status is asked for once per screen, however often the banners change")
    func statusIsRequestedOnce() async {
        let service = InAppSurveyResponsesServiceStub(completionResult: .success(true))
        let banners = CurrentValueSubject<[CallToActionMarketingBanner], Never>([waitlist])
        let (filter, output) = makeOutput(service: service, banners: banners)
        var iterator = output.makeAsyncIterator()

        #expect(await iterator.next() == [waitlist])
        #expect(await iterator.next() == [])

        banners.send([waitlist, partner])

        #expect(await iterator.next() == [partner])
        #expect(service.statusRequestCount == 1)
        withExtendedLifetime(filter) {}
    }

    @Test("A completion learned from the backend hides the banner on the next Buy screen at once, without asking again")
    func backendCompletionOutlivesTheScreen() async {
        let service = InAppSurveyResponsesServiceStub(completionResult: .success(true))
        let sessionStore = CommonInAppSurveySessionStore()
        let banners = CurrentValueSubject<[CallToActionMarketingBanner], Never>([waitlist, partner])
        let (firstFilter, firstOutput) = makeOutput(service: service, sessionStore: sessionStore, banners: banners)
        var firstIterator = firstOutput.makeAsyncIterator()

        #expect(await firstIterator.next() == [waitlist, partner])
        #expect(await firstIterator.next() == [partner])
        withExtendedLifetime(firstFilter) {}

        let (secondFilter, secondOutput) = makeOutput(service: service, sessionStore: sessionStore, banners: banners)
        var secondIterator = secondOutput.makeAsyncIterator()

        #expect(await secondIterator.next() == [partner])
        #expect(service.statusRequestCount == 1)
        withExtendedLifetime(secondFilter) {}
    }

    @Test("A survey submitted in this session hides the Waitlist banner even when the backend hasn't caught up")
    func sessionCompletionHidesWaitlist() async {
        let service = InAppSurveyResponsesServiceStub(completionResult: .success(false))
        let sessionStore = CommonInAppSurveySessionStore()
        let banners = CurrentValueSubject<[CallToActionMarketingBanner], Never>([partner])
        let (filter, output) = makeOutput(service: service, sessionStore: sessionStore, banners: banners)
        var iterator = output.makeAsyncIterator()

        #expect(await iterator.next() == [partner])

        sessionStore.markCompleted(surveyId: .demand, userWalletId: userWalletId)
        banners.send([waitlist, partner])

        #expect(await iterator.next() == [partner])
        #expect(await iterator.next() == [partner])
        #expect(service.statusRequestCount == 0)
        withExtendedLifetime(filter) {}
    }

    @Test("Another wallet's completion doesn't hide this wallet's banner")
    func completionIsPerWallet() async {
        let service = InAppSurveyResponsesServiceStub(completionResult: .failure(InAppSurveyResponsesServiceStub.StubError.failed))
        await expectWaitlistKept(
            service: service,
            completedUserWalletId: UserWalletId(value: Data(repeating: 0xCD, count: 32))
        )
    }
}

// MARK: - Waiting for the status request

private extension ConciergeWaitlistBannerFilterTests {
    func expectWaitlistKept(service: InAppSurveyResponsesServiceStub, completedUserWalletId: UserWalletId? = nil) async {
        let (storeReleased, storeReleasedContinuation) = AsyncStream<Void>.makeStream()
        let banners = CurrentValueSubject<[CallToActionMarketingBanner], Never>([waitlist, partner])
        var filter: ConciergeWaitlistBannerFilter? = makeFilter(
            service: service,
            completedUserWalletId: completedUserWalletId,
            onStoreRelease: { storeReleasedContinuation.finish() }
        )
        let output = filter?.filter(banners.eraseToAnyPublisher())
            .buffer(size: 16, prefetch: .keepFull, whenFull: .dropOldest)
            .eraseToAnyPublisher()
        var iterator = output?.values.makeAsyncIterator()

        #expect(await iterator?.next() == [waitlist, partner])

        filter = nil
        for await _ in storeReleased {}
        banners.send([waitlist, partner])

        #expect(await iterator?.next() == [waitlist, partner])
    }

    func makeFilter(
        service: InAppSurveyResponsesServiceStub,
        completedUserWalletId: UserWalletId?,
        onStoreRelease: @escaping () -> Void
    ) -> ConciergeWaitlistBannerFilter {
        let sessionStore = ReleaseReportingSessionStore(onRelease: onStoreRelease)

        if let completedUserWalletId {
            sessionStore.markCompleted(surveyId: .demand, userWalletId: completedUserWalletId)
        }

        return ConciergeWaitlistBannerFilter(userWalletId: userWalletId, responsesService: service, sessionStore: sessionStore)
    }
}

private final class ReleaseReportingSessionStore: InAppSurveySessionStore {
    private let store = CommonInAppSurveySessionStore()
    private let onRelease: () -> Void

    init(onRelease: @escaping () -> Void) {
        self.onRelease = onRelease
    }

    deinit {
        onRelease()
    }

    func markCompleted(surveyId: InAppSurveyId, userWalletId: UserWalletId) {
        store.markCompleted(surveyId: surveyId, userWalletId: userWalletId)
    }

    func isCompletedPublisher(surveyId: InAppSurveyId, userWalletId: UserWalletId) -> AnyPublisher<Bool, Never> {
        store.isCompletedPublisher(surveyId: surveyId, userWalletId: userWalletId)
    }
}
