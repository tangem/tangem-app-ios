//
//  CollectiblesPackRevealViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import Testing
import UIKit
import TangemFoundation
import TangemLocalization
import TangemTestKit
@testable import Tangem

@Suite("CollectiblesPackRevealViewModel", .timeLimit(.minutes(1)))
@MainActor
final class CollectiblesPackRevealViewModelTests: LeakTrackingTestSuite {
    typealias SUT = CollectiblesPackRevealViewModel

    // MARK: - Offer

    @Test("A card without an address has no buyback to check")
    func cardWithoutAddressHasNoOffer() async {
        let (sut, doubles) = makeSUT(nftAddress: nil)

        #expect(sut.sellBackState == .unavailable)

        await sut.checkOffer()

        #expect(doubles.offerProvider.loadedAddresses.isEmpty)
    }

    @Test("The screen opens checking the card's offer and stops once the backend prices it")
    func offerStopsTheCheck() async {
        let (sut, doubles) = makeSUT()

        #expect(sut.sellBackState == .checking)
        #expect(sut.shouldCheckOffer)

        await sut.checkOffer()

        #expect(sut.sellBackState == .available(Constants.offer))
        #expect(!sut.shouldCheckOffer)
        #expect(doubles.offerProvider.loadedAddresses == [Constants.nftAddress])
    }

    @Test(
        "No offer or a failed check shows the buyback as unavailable and keeps asking",
        arguments: FirstAnswer.allCases
    )
    func missingOfferKeepsAsking(firstAnswer: FirstAnswer) async {
        let (sut, doubles) = makeSUT(offers: [firstAnswer.result, .success(Constants.offer)])
        var states: [SUT.SellBackState] = []
        let subscription = sut.$sellBackState.sink { states.append($0) }

        await sut.checkOffer()

        #expect(states == [.checking, .unavailable, .available(Constants.offer)])
        #expect(doubles.offerProvider.loadedAddresses.count == 2)
        subscription.cancel()
    }

    @Test("An offer already on screen is not asked for again")
    func availableOfferIsNotRechecked() async {
        let (sut, doubles) = makeSUT()

        await sut.checkOffer()
        await sut.checkOffer()

        #expect(doubles.offerProvider.loadedAddresses.count == 1)
    }

    @Test("The background pauses the offer check and the foreground resumes it")
    func backgroundPausesOfferCheck() async {
        let notificationCenter = NotificationCenter()
        let (sut, doubles) = makeSUT(notificationCenter: notificationCenter)

        await keepPosting(.didEnterBackground, on: notificationCenter) { !sut.shouldCheckOffer }
        await sut.checkOffer()

        #expect(sut.sellBackState == .checking)
        #expect(doubles.offerProvider.loadedAddresses.isEmpty)

        await keepPosting(.willEnterForeground, on: notificationCenter) { sut.shouldCheckOffer }
        await sut.checkOffer()

        #expect(sut.sellBackState == .available(Constants.offer))
    }

    // MARK: - Sell back

    @Test("Sell back hands the card and its offer to the sale and returns to the machine once sold")
    func sellBackSellsTheCard() async {
        let (sut, doubles) = makeSUT()
        await sut.checkOffer()

        sut.sellBack()

        #expect(sut.sellBackState == .selling(Constants.offer))
        await waitUntil { doubles.balanceRefresher.callsCount == 1 }
        #expect(doubles.interactor.sales == [Sale(nftAddress: Constants.nftAddress, offer: Constants.offer)])
        #expect(doubles.routable.returnsCount == 1)
    }

    @Test("A failed sale asks for the offer again instead of trusting the old one", arguments: [
        CollectiblesBuybackSaleError.failed,
        .notConfirmed,
        .accountNotReady,
    ])
    func failedSaleRechecksOffer(error: CollectiblesBuybackSaleError) async {
        let (sut, doubles) = makeSUT(saleResults: [.failure(error)])

        await sellBack(sut, in: doubles)

        #expect(sut.sellBackState == .checking)
        #expect(doubles.routable.returnsCount == 0)

        await sut.checkOffer()

        #expect(doubles.offerProvider.loadedAddresses.count == 2)
        #expect(sut.sellBackState == .available(Constants.offer))
    }

    @Test("A cancelled sale keeps the offer on the button")
    func cancelledSaleKeepsOffer() async {
        let (sut, doubles) = makeSUT(saleResults: [.failure(CancellationError())])

        await sellBack(sut, in: doubles)

        #expect(sut.sellBackState == .available(Constants.offer))
        #expect(doubles.routable.returnsCount == 0)
    }

    @Test("Sell back does nothing before an offer is on screen")
    func sellBackNeedsOffer() async {
        let (sut, doubles) = makeSUT()

        sut.sellBack()
        await Task.yield()

        #expect(sut.sellBackState == .checking)
        #expect(doubles.interactor.sales.isEmpty)
    }

    @Test("A second tap while the sale runs is ignored")
    func secondTapIsIgnored() async {
        let (sut, doubles) = makeSUT()
        await sut.checkOffer()

        sut.sellBack()
        sut.sellBack()

        await waitUntil { doubles.balanceRefresher.callsCount == 1 }
        #expect(doubles.interactor.sales.count == 1)
    }

    // MARK: - Prize

    @Test("The prize carries the card's texts for the screen")
    func prizeCarriesCardTexts() {
        let (sut, _) = makeSUT()
        let marketValue = CollectiblesPriceFormatter.formatWithCents(Constants.insuredValue)

        #expect(sut.prize.name == "2024 Base Set")
        #expect(sut.prize.number == "#12")
        #expect(sut.prize.rarityTitle == Localization.collectiblesOpenPackPullRare)
        #expect(sut.prize.subtitle == Localization.collectiblesOpenPackMarketValue(marketValue))
        #expect(sut.prize.keepTitle == Localization.collectiblesOpenPackKeepCardButton)
        #expect(sut.prize.imageURL == Constants.frontImageURL)
    }
}

// MARK: - Arguments

extension CollectiblesPackRevealViewModelTests {
    enum FirstAnswer: CaseIterable, Sendable {
        case noOffer
        case failure

        var result: Result<CollectiblesBuybackOffer?, any Error> {
            switch self {
            case .noOffer: .success(nil)
            case .failure: .failure(URLError(.badServerResponse))
            }
        }
    }
}

// MARK: - Helpers

private extension CollectiblesPackRevealViewModelTests {
    struct Sale: Equatable {
        let nftAddress: String
        let offer: CollectiblesBuybackOffer
    }

    struct Doubles {
        let offerProvider: OfferProviderStub
        let interactor: BuybackInteractorStub
        let routable: RevealRoutableSpy
        let balanceRefresher: BalanceRefreshSpy
    }

    enum Constants {
        static let nftAddress = "nft-1"
        static let offer = CollectiblesBuybackOffer(amount: Decimal(string: "12.75")!, expiresAt: nil)
        static let insuredValue: Decimal = 49
        static let frontImageURL = URL(string: "https://example.com/front.png")!
    }

    static func wonCard(nftAddress: String?) -> CollectiblesWonCard {
        CollectiblesWonCard(
            nftAddress: nftAddress,
            imageFrontURL: Constants.frontImageURL,
            imageBackURL: nil,
            gradingCompany: "PSA",
            grade: "GEM-MT 10",
            gradingID: "grading-1",
            rarity: .rare,
            year: "2024",
            set: "Base Set",
            serialNumber: "12",
            insuredValue: Constants.insuredValue
        )
    }

    func makeSUT(
        nftAddress: String? = Constants.nftAddress,
        offers: [Result<CollectiblesBuybackOffer?, any Error>] = [.success(Constants.offer)],
        saleResults: [Result<Void, any Error>] = [.success(())],
        notificationCenter: NotificationCenter = NotificationCenter()
    ) -> (SUT, Doubles) {
        let doubles = Doubles(
            offerProvider: OfferProviderStub(results: offers),
            interactor: BuybackInteractorStub(results: saleResults),
            routable: RevealRoutableSpy(),
            balanceRefresher: BalanceRefreshSpy()
        )
        let sut = SUT(
            darkVideoURL: nil,
            lightVideoURL: nil,
            wonCard: Self.wonCard(nftAddress: nftAddress),
            player: RevealPlayerStub(),
            offerProvider: doubles.offerProvider,
            buybackInteractor: doubles.interactor,
            signingActionButtonType: .requiredNFCInteraction,
            routable: doubles.routable,
            delayProvider: InstantPollDelayProvider(),
            notificationCenter: notificationCenter,
            refreshBalance: { @MainActor [balanceRefresher = doubles.balanceRefresher] in balanceRefresher.refresh() }
        )
        return (trackForMemoryLeaks(sut), doubles)
    }

    func sellBack(_ sut: SUT, in doubles: Doubles) async {
        await sut.checkOffer()
        sut.sellBack()
        await waitUntil { doubles.balanceRefresher.callsCount == 1 }
    }

    func keepPosting(
        _ event: NotificationCenter.AppEvent,
        on notificationCenter: NotificationCenter,
        until condition: @escaping @MainActor () -> Bool
    ) async {
        await waitUntil {
            notificationCenter.post(event)
            return condition()
        }
    }

    func waitUntil(timeout: Duration = .seconds(5), _ condition: @escaping @MainActor () -> Bool) async {
        let deadline = ContinuousClock.now + timeout
        while !condition() {
            if ContinuousClock.now >= deadline {
                Issue.record("waitUntil timed out")
                return
            }

            do {
                try await Task.sleep(for: .milliseconds(10))
            } catch {
                return
            }
        }
    }
}

private extension NotificationCenter {
    enum AppEvent {
        case didEnterBackground
        case willEnterForeground
    }

    func post(_ event: AppEvent) {
        switch event {
        case .didEnterBackground: post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        case .willEnterForeground: post(name: UIApplication.willEnterForegroundNotification, object: nil)
        }
    }
}

// MARK: - Stubs

@MainActor
private final class OfferProviderStub: CollectiblesBuybackOfferProvider {
    private(set) var loadedAddresses: [String] = []

    private var results: [Result<CollectiblesBuybackOffer?, any Error>]

    init(results: [Result<CollectiblesBuybackOffer?, any Error>]) {
        self.results = results
    }

    func load(nftAddress: String) async throws -> CollectiblesBuybackOffer? {
        loadedAddresses.append(nftAddress)
        return try (results.count > 1 ? results.removeFirst() : results[0]).get()
    }
}

@MainActor
private final class BuybackInteractorStub: CollectiblesBuybackInteractor {
    private(set) var sales: [CollectiblesPackRevealViewModelTests.Sale] = []

    private var results: [Result<Void, any Error>]

    init(results: [Result<Void, any Error>]) {
        self.results = results
    }

    func sell(nftAddress: String, offer: CollectiblesBuybackOffer) async throws {
        sales.append(.init(nftAddress: nftAddress, offer: offer))
        try (results.count > 1 ? results.removeFirst() : results[0]).get()
    }
}

@MainActor
private final class RevealRoutableSpy: CollectiblesPackRevealRoutable {
    private(set) var returnsCount = 0

    func returnToMachine() {
        returnsCount += 1
    }
}

@MainActor
private final class BalanceRefreshSpy {
    private(set) var callsCount = 0

    func refresh() {
        callsCount += 1
    }
}

private final class RevealPlayerStub: CollectiblesRevealPlayer {
    var videoPlayerPublisher: AnyPublisher<AVPlayer?, Never> {
        Just(nil).eraseToAnyPublisher()
    }

    func play(videoURL: URL?) async throws -> CollectiblesRevealPlayerResult {
        CollectiblesRevealPlayerResult(isSkipped: false)
    }

    func skip() {}
}
