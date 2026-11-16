//
//  AppSessionDeeplinkRespondersTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
@testable import Tangem

/// What happens to a link that arrives while no wallet session is on screen, and inside one.
@Suite("Deeplink session door", .serialized)
@MainActor
struct AppSessionDeeplinkRespondersTests {
    private let promoPageStorage = PromoPageStorageStub()

    @Test("A link arriving with no session waits for the main screen, and is handed over once")
    func linkWithoutSessionWaits() async {
        await withRepository {
            let responders = AppSessionDeeplinkResponders()
            responders.start()

            handler.handleIncomingURL(Deeplink.markets)

            #expect(responders.takeWaitingAction() == Constants.markets)
            #expect(responders.takeWaitingAction() == nil)
        }
    }

    @Test("A promo page link opened with no session is saved and handed over once")
    func promoPageIsSavedAndHandedOverOnce() async {
        await withRepository {
            let responders = makeSUT()
            responders.start()

            handler.handleIncomingURL(Deeplink.promoPage)

            #expect(promoPageStorage.pendingPage == Constants.promoPageAddress)
            #expect(responders.takeWaitingAction() == Constants.promoPage)
            #expect(responders.takeWaitingAction() == nil)
            #expect(promoPageStorage.pendingPage == nil)
        }
    }

    @Test("A promo page link opened after the app locks is saved and waits for the main screen")
    func promoPageWaitsForUnlock() async {
        let repository = UserWalletRepositoryEventsStub(models: [ConfiguredUserWalletModelStub.card()])

        await withRepository(repository) {
            let responders = makeSUT()
            responders.start()
            responders.beginSession()

            await repository.emit(.locked)
            handler.handleIncomingURL(Deeplink.promoPage)

            #expect(promoPageStorage.pendingPage == Constants.promoPageAddress)
            #expect(responders.takeWaitingAction() == Constants.promoPage)
        }
    }

    @Test("A promo page saved before the app was closed waits for the main screen")
    func savedPromoPageWaitsAfterRelaunch() async {
        await withRepository {
            promoPageStorage.pendingPage = Constants.promoPageAddress
            let responders = makeSUT()
            responders.start()

            #expect(responders.takeWaitingAction() == Constants.promoPage)
            #expect(promoPageStorage.pendingPage == nil)
        }
    }

    @Test("A link opened after a promo page saved before the app was closed is the one handed over")
    func laterLinkReplacesRestoredPromoPage() async {
        await withRepository {
            promoPageStorage.pendingPage = Constants.promoPageAddress
            let responders = makeSUT()
            responders.start()

            handler.handleIncomingURL(Deeplink.markets)

            #expect(promoPageStorage.pendingPage == nil)
            #expect(responders.takeWaitingAction() == Constants.markets)
        }
    }

    @Test("A promo page link without a page drops the page saved before")
    func promoPageLinkWithoutPageDropsSavedPage() async {
        await withRepository {
            promoPageStorage.pendingPage = Constants.promoPageAddress
            let responders = makeSUT()
            responders.start()

            handler.handleIncomingURL(Deeplink.promoPageWithoutPage)

            #expect(promoPageStorage.pendingPage == nil)
        }
    }

    @Test("With the toggle off a promo page waits like any link and isn't saved")
    func promoPageWithToggleOffIsNotSaved() async {
        await withRepository {
            let responders = makeSUT(isPromoPageEnabled: false)
            responders.start()

            handler.handleIncomingURL(Deeplink.promoPage)

            #expect(promoPageStorage.pendingPage == nil)
            #expect(responders.takeWaitingAction() == Constants.promoPage)
        }
    }

    @Test("A link opened after a saved promo page is the one handed over")
    func laterLinkReplacesPromoPage() async {
        await withRepository {
            let responders = makeSUT()
            responders.start()

            handler.handleIncomingURL(Deeplink.promoPage)
            handler.handleIncomingURL(Deeplink.markets)

            #expect(responders.takeWaitingAction() == Constants.markets)
            #expect(promoPageStorage.pendingPage == nil)
        }
    }

    @Test("A promo page opened after another link is the one handed over")
    func laterPromoPageReplacesLink() async {
        await withRepository {
            let responders = makeSUT()
            responders.start()

            handler.handleIncomingURL(Deeplink.markets)
            handler.handleIncomingURL(Deeplink.promoPage)

            #expect(promoPageStorage.pendingPage == Constants.promoPageAddress)
            #expect(responders.takeWaitingAction() == Constants.promoPage)
        }
    }

    @Test("A newer link takes the place of the one waiting")
    func newerLinkTakesThePlace() async {
        await withRepository {
            let responders = AppSessionDeeplinkResponders()
            responders.start()

            handler.handleIncomingURL(Deeplink.markets)
            handler.handleIncomingURL(Deeplink.news)

            #expect(responders.takeWaitingAction() == Constants.news)
        }
    }

    @Test("A request to scan means nothing later and isn't kept")
    func scanRequestIsNotKept() async {
        await withRepository {
            let responders = AppSessionDeeplinkResponders()
            responders.start()

            handler.handleIncomingURL(Deeplink.blockchainScheme)

            #expect(responders.takeWaitingAction() == nil)
        }
    }

    @Test("Inside a session nothing waits: a link nobody shows is gone")
    func nothingWaitsInsideASession() async {
        await withRepository {
            let responders = AppSessionDeeplinkResponders()
            responders.start()
            responders.beginSession()
            defer { responders.endSession() }

            // No session responder has a screen for the payment account; it is the main screen's to open.
            handler.handleIncomingURL(Deeplink.paymentAccount)

            #expect(responders.takeWaitingAction() == nil)
        }
    }

    @Test("Once the session ends the door is kept again")
    func doorIsKeptAgainAfterTheSession() async {
        await withRepository {
            let responders = AppSessionDeeplinkResponders()
            responders.start()
            responders.beginSession()
            responders.endSession()

            handler.handleIncomingURL(Deeplink.markets)

            #expect(responders.takeWaitingAction() == Constants.markets)
        }
    }
}

// MARK: - Environment

private extension AppSessionDeeplinkRespondersTests {
    var handler: IncomingActionHandler {
        InjectedValues[\.incomingActionHandler]
    }

    func makeSUT(isPromoPageEnabled: Bool = true) -> AppSessionDeeplinkResponders {
        AppSessionDeeplinkResponders(promoPageService: PromoPageService(isEnabled: isPromoPageEnabled))
    }

    func withRepository(_ repository: UserWalletRepository = FakeUserWalletRepository(models: []), _ body: () async -> Void) async {
        await InjectedDependenciesIsolation.shared.run {
            let previousRepository = InjectedValues[\.userWalletRepository]
            let previousPromoPageStorage = InjectedValues[\.promoPageStorage]
            InjectedValues[\.userWalletRepository] = repository
            InjectedValues[\.promoPageStorage] = promoPageStorage

            defer {
                InjectedValues[\.userWalletRepository] = previousRepository
                InjectedValues[\.promoPageStorage] = previousPromoPageStorage
            }

            await body()
        }
    }

    enum Deeplink {
        static let markets = URL(string: "tangem://markets")!
        static let news = URL(string: "tangem://news")!
        static let paymentAccount = URL(string: "tangem://pay-account")!
        static let blockchainScheme = URL(string: "bitcoin:bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq")!
        static let promoPage = URL(string: "tangem://promo_page?page=https%3A%2F%2Fpromo.tangem.com%2Fprize-draw-status%2F%3Fsuccess")!
        static let promoPageWithoutPage = URL(string: "tangem://promo_page")!
    }

    enum Constants {
        static let markets = IncomingAction.navigation(.markets(MarketsDeeplink(order: nil, interval: nil)))
        static let news = IncomingAction.navigation(.news(NewsDeeplink(newsId: nil, categoryId: nil)))
        static let promoPageAddress = "https://promo.tangem.com/prize-draw-status/?success"
        static let promoPage = IncomingAction.navigation(.promoPage(PromoPageDeeplink(page: promoPageAddress)))
    }
}

// MARK: - Stubs

private final class UserWalletRepositoryEventsStub: FakeUserWalletRepository {
    private let eventSubject = PassthroughSubject<UserWalletRepositoryEvent, Never>()

    override var eventProvider: AnyPublisher<UserWalletRepositoryEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    func emit(_ event: UserWalletRepositoryEvent) async {
        var delivery: AnyCancellable?

        await withCheckedContinuation { continuation in
            delivery = eventSubject
                .receive(on: DispatchQueue.main)
                .first()
                .sink { _ in continuation.resume() }

            eventSubject.send(event)
        }

        delivery?.cancel()
    }
}
