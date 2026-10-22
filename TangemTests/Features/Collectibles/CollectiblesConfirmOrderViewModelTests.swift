//
//  CollectiblesConfirmOrderViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import SwiftUI
import Testing
import TangemFoundation
import TangemLocalization
import TangemTestKit
@testable import TangemCollectibles
@testable import Tangem

@Suite("CollectiblesConfirmOrderViewModel", .timeLimit(.minutes(1)))
@MainActor
final class CollectiblesConfirmOrderViewModelTests: LeakTrackingTestSuite {
    typealias SUT = CollectiblesConfirmOrderViewModel

    // MARK: - Order

    @Test("Lists the pack, the platform fee and the total in USDC straight from the machine")
    func listsOrderRows() {
        let (sut, _) = makeSUT()
        let expectedTitle = "\(Constants.machineName) x1"
        let expectedValues = [
            CollectiblesPriceFormatter.format(Constants.price),
            CollectiblesPriceFormatter.format(Constants.platformFee),
            CollectiblesPriceFormatter.formatAmount(Constants.total, ticker: Self.ticker),
        ]

        #expect(sut.rows.map(\.kind) == [.pack, .fee, .total])
        #expect(sut.rows.first?.title == expectedTitle)
        #expect(sut.rows.map(\.value) == expectedValues)
        #expect(sut.artworkURL == Constants.artworkURL)
    }

    @Test("Close leaves the pack flow")
    func closeLeavesFlow() {
        let (sut, doubles) = makeSUT()

        sut.close()

        #expect(doubles.routable.closePackFlowCallsCount == 1)
    }

    // MARK: - Balance

    @Test("The button follows the vault balance", arguments: Self.balanceArguments)
    func buttonFollowsBalance(balance: TokenBalanceType, expected: SUT.ButtonState) async {
        let (sut, _) = makeSUT(balance: balance)

        await waitUntil { sut.buttonState == expected }

        #expect(sut.buttonState == expected)
    }

    @Test("A balance that goes back to loading keeps the last known button")
    func reloadingBalanceKeepsButton() async {
        let (sut, doubles) = makeSUT()
        let states = PublisherRecorder(sut.$buttonState.removeDuplicates().eraseToAnyPublisher())
        await waitUntil { sut.buttonState == .approve }

        doubles.balanceProvider.updateBalance(.loading(nil))
        doubles.balanceProvider.updateBalance(.loaded(Constants.total - 1))
        await waitUntil { sut.buttonState == .notEnoughFunds }

        #expect(states.values == [.balanceLoading, .approve, .notEnoughFunds])
    }

    @Test("An unfinished purchase keeps the button approvable whatever the balance", arguments: Self.unfinishedBalances)
    func unfinishedPurchaseKeepsApprove(balance: TokenBalanceType) async {
        let (sut, _) = makeSUT(balance: balance, hasUnfinishedPurchase: true)

        await waitUntil { sut.buttonState == .approve }

        #expect(sut.buttonState == .approve)
    }

    @Test("Retry refreshes the balance only while it is unavailable", arguments: Self.retryArguments)
    func retryRefreshesUnavailableBalance(balance: TokenBalanceType, state: SUT.ButtonState, refreshes: Int) async {
        let (sut, doubles) = makeSUT(balance: balance)
        await waitUntil { sut.buttonState == state }

        sut.retryBalance()
        await waitUntil { doubles.balanceRefresher.callsCount == refreshes }

        let expectedState: SUT.ButtonState = refreshes > 0 ? .balanceLoading : state
        #expect(doubles.balanceRefresher.callsCount == refreshes)
        #expect(sut.buttonState == expectedState)
    }

    // MARK: - Approve

    @Test("Approve does nothing while the button is not approvable", arguments: Self.notApprovableArguments)
    func approveIgnoredWhenNotApprovable(balance: TokenBalanceType, state: SUT.ButtonState) async {
        let (sut, doubles) = makeSUT(balance: balance)
        await waitUntil { sut.buttonState == state }

        sut.approve()

        #expect(sut.buttonState == state)
        #expect(doubles.interactor.purchases.isEmpty)
    }

    @Test("Approve buys the shown pack and asks the router to reveal the won card")
    func approveAsksForReveal() async {
        let (sut, doubles) = makeSUT()
        await waitUntil { sut.buttonState == .approve }

        sut.approve()
        #expect(sut.buttonState == .generating)
        await waitUntil { doubles.balanceRefresher.callsCount == 1 }

        let expectedPurchase = PurchaseRequest(
            machineID: Constants.machineID,
            price: Constants.price,
            platformFee: Constants.platformFee,
            isTurboModeOn: false
        )
        #expect(doubles.interactor.purchases == [expectedPurchase])
        #expect(doubles.routable.revealCards.map(\.imageFrontURL) == [Constants.frontImageURL])
        #expect(sut.revealViewModel == nil)
        #expect(sut.errorMessage == nil)
    }

    @Test("The router gets the preloaded media together with the prize")
    func routerGetsPreloadedMedia() async {
        let (sut, doubles) = makeSUT()
        await waitUntil { sut.buttonState == .approve }

        await approve(sut, in: doubles)

        #expect(doubles.routable.revealAssets.map(\.darkVideoURL) == [Constants.darkVideoURL])
        #expect(doubles.routable.revealAssets.map(\.lightVideoURL) == [Constants.lightVideoURL])
        #expect(doubles.routable.revealAssets.map(\.skipAudioURL) == [Constants.skipAudioURL])
    }

    @Test("A reveal handed over by the router is shown as the generated pack")
    func showsRevealFromRouter() async {
        let (sut, doubles) = makeSUT()
        await waitUntil { sut.buttonState == .approve }
        await approve(sut, in: doubles)
        let reveal = Self.makeRevealViewModel()

        sut.show(reveal: reveal)

        #expect(sut.revealViewModel === reveal)
        #expect(sut.buttonState == .packGenerated)
    }

    @Test("Only the card images that exist are prefetched for the reveal", arguments: Self.cardImageArguments)
    func prefetchesExistingCardImages(backImageURL: URL?, expected: [URL]) async {
        let wonCard = Self.wonCard(backImageURL: backImageURL)
        let (sut, doubles) = makeSUT(results: [.success(.wonCard(wonCard))])
        await waitUntil { sut.buttonState == .approve }

        await approve(sut, in: doubles)

        #expect(doubles.preloader.prefetchedImageURLs == [expected])
    }

    @Test("The button walks the purchase steps and ends with the generated pack")
    func buttonWalksSteps() async {
        let (sut, doubles) = makeSUT(steps: [.generating, .confirming, .opening])
        let states = PublisherRecorder(sut.$buttonState.removeDuplicates().eraseToAnyPublisher())
        await waitUntil { sut.buttonState == .approve }

        await approve(sut, in: doubles)
        sut.show(reveal: Self.makeRevealViewModel())

        #expect(states.values == [.balanceLoading, .approve, .generating, .confirming, .opening, .packGenerated])
    }

    @Test("Turbo mode is passed to the purchase", arguments: [false, true])
    func passesTurboMode(isTurboModeOn: Bool) async {
        let (sut, doubles) = makeSUT(isTurboModeOn: isTurboModeOn)
        await waitUntil { sut.buttonState == .approve }

        await approve(sut, in: doubles)

        #expect(doubles.interactor.purchases.map(\.isTurboModeOn) == [isTurboModeOn])
    }

    @Test("A second tap during the purchase does not start another one")
    func secondTapIsIgnored() async {
        let (sut, doubles) = makeSUT()
        await waitUntil { sut.buttonState == .approve }

        sut.approve()
        sut.approve()
        await waitUntil { doubles.balanceRefresher.callsCount == 1 }

        #expect(doubles.interactor.purchases.count == 1)
    }

    // MARK: - Reveal media

    @Test("The reveal media is preloaded for the theme on appear and again on approve", arguments: Self.colorSchemes)
    func preloadsRevealMedia(colorScheme: ColorScheme) async {
        let (sut, doubles) = makeSUT()
        await waitUntil { sut.buttonState == .approve }

        sut.preloadRevealAssets(for: colorScheme, isReduceMotionEnabled: false)
        await approve(sut, in: doubles)

        #expect(doubles.preloader.preloadedColorSchemes == [colorScheme, colorScheme])
    }

    @Test("Reduce Motion stops the reveal media from loading")
    func reduceMotionSkipsPreload() async {
        let (sut, doubles) = makeSUT()
        await waitUntil { sut.buttonState == .approve }

        sut.preloadRevealAssets(for: .dark, isReduceMotionEnabled: false)
        sut.preloadRevealAssets(for: .dark, isReduceMotionEnabled: true)
        await approve(sut, in: doubles)

        #expect(doubles.preloader.preloadedColorSchemes == [.dark])
    }

    // MARK: - Auto buyback

    @Test(
        "An auto buyback shows the buyback complete sheet with the sold amount instead of the reveal",
        .enabled(if: Self.isSystemSheetAvailable)
    )
    func autoBuybackShowsSheet() async {
        let (sut, doubles) = makeSUT(results: [.success(.autoSold(amount: Constants.buybackAmount))])
        await waitUntil { sut.buttonState == .approve }

        await approve(sut, in: doubles)

        let soldAmount = CollectiblesPriceFormatter.formatAmount(Constants.buybackAmount, ticker: Self.ticker)
        #expect(sut.buybackCompleteSheetViewModel.isPresented)
        #expect(sut.buybackCompleteSheetViewModel.model.message.contains(soldAmount))
        #expect(sut.revealViewModel == nil)
        #expect(sut.buttonState == .approve)
    }

    @Test(
        "Open again from the buyback complete sheet buys another pack once the sheet is dismissed",
        .enabled(if: Self.isSystemSheetAvailable)
    )
    func buybackCompleteOpensAgain() async {
        let results: [Result<CollectiblesPackPurchaseResult, any Error>] = [
            .success(.autoSold(amount: nil)),
            .success(.wonCard(Self.wonCard)),
        ]
        let (sut, doubles) = makeSUT(results: results)
        await waitUntil { sut.buttonState == .approve }
        await approve(sut, in: doubles)

        sut.buybackCompleteSheetViewModel.primary()
        #expect(doubles.interactor.purchases.count == 1)

        sut.buybackCompleteSheetViewModel.didDismiss()
        await waitUntil { doubles.balanceRefresher.callsCount == 2 }

        #expect(doubles.interactor.purchases.count == 2)
        #expect(doubles.routable.revealCards.count == 1)
    }

    @Test(
        "Explore packs from the buyback complete sheet leaves the flow once the sheet is dismissed",
        .enabled(if: Self.isSystemSheetAvailable)
    )
    func buybackCompleteExplorePacksLeavesFlow() async {
        let (sut, doubles) = makeSUT(results: [.success(.autoSold(amount: nil))])
        await waitUntil { sut.buttonState == .approve }
        await approve(sut, in: doubles)

        sut.buybackCompleteSheetViewModel.secondary()
        #expect(doubles.routable.closePackFlowCallsCount == 0)

        sut.buybackCompleteSheetViewModel.didDismiss()

        #expect(doubles.routable.closePackFlowCallsCount == 1)
        #expect(doubles.interactor.purchases.count == 1)
    }

    // MARK: - Failures

    @Test("Low inventory shows its sheet and leaves the order approvable", .enabled(if: Self.isSystemSheetAvailable))
    func lowInventoryShowsSheet() async {
        let (sut, doubles) = makeSUT(results: [.failure(CollectiblesPackPurchaseError.lowInventory)])
        await waitUntil { sut.buttonState == .approve }

        await approve(sut, in: doubles)

        #expect(sut.lowInventorySheetViewModel.isPresented)
        #expect(sut.errorMessage == nil)
        #expect(sut.buttonState == .approve)
    }

    @Test(
        "The low inventory buttons route once the sheet is dismissed",
        .enabled(if: Self.isSystemSheetAvailable),
        arguments: SheetButton.allCases
    )
    func lowInventoryRoutes(button: SheetButton) async {
        let (sut, doubles) = makeSUT(results: [.failure(CollectiblesPackPurchaseError.lowInventory)])
        await waitUntil { sut.buttonState == .approve }
        await approve(sut, in: doubles)

        tap(button, on: sut.lowInventorySheetViewModel)
        #expect(doubles.routable.closePackFlowCallsCount == 0)
        #expect(doubles.routable.returnToMachineCallsCount == 0)

        sut.lowInventorySheetViewModel.didDismiss()

        let expectedCloseCalls = button == .primary ? 1 : 0
        let expectedReturnCalls = button == .secondary ? 1 : 0
        #expect(doubles.routable.closePackFlowCallsCount == expectedCloseCalls)
        #expect(doubles.routable.returnToMachineCallsCount == expectedReturnCalls)
    }

    @Test(
        "An unopened pack shows its sheet and Open pack continues the same order",
        .enabled(if: Self.isSystemSheetAvailable),
        arguments: Self.unopenedErrors
    )
    func unopenedPackSheetRetries(error: CollectiblesPackPurchaseError) async {
        let (sut, doubles) = makeSUT(results: [.failure(error), .success(.wonCard(Self.wonCard))])
        await waitUntil { sut.buttonState == .approve }
        await approve(sut, in: doubles)

        #expect(sut.packUnopenedSheetViewModel.isPresented)
        #expect(sut.errorMessage == nil)

        sut.packUnopenedSheetViewModel.primary()
        await waitUntil { doubles.balanceRefresher.callsCount == 2 }

        #expect(!sut.packUnopenedSheetViewModel.isPresented)
        #expect(doubles.interactor.purchases.count == 2)
        #expect(doubles.routable.revealCards.count == 1)
    }

    @Test("Other failures show the generic message and restore the button", arguments: Self.genericFailures)
    func genericFailureShowsMessage(error: any Error) async {
        let (sut, doubles) = makeSUT(results: [.failure(error)])
        defer { sut.dismissError() }
        await waitUntil { sut.buttonState == .approve }

        await approve(sut, in: doubles)

        #expect(sut.errorMessage == Localization.commonSomethingWentWrong)
        #expect(sut.buttonState == .approve)
        #expect(sut.revealViewModel == nil)
    }

    @Test("Expired and refunded payments get their own messages")
    func closedPaymentsHaveOwnMessages() async {
        let expired = await errorMessage(after: .paymentFailed(.expired))
        let refunded = await errorMessage(after: .paymentFailed(.refunded))

        #expect(expired != nil)
        #expect(refunded != nil)
        #expect(expired != refunded)
        #expect(expired != Localization.commonSomethingWentWrong)
        #expect(refunded != Localization.commonSomethingWentWrong)
    }

    @Test("Dismissing the error clears the message")
    func dismissErrorClearsMessage() async {
        let (sut, doubles) = makeSUT(results: [.failure(CollectiblesPackPurchaseError.paymentTimedOut)])
        await waitUntil { sut.buttonState == .approve }
        await approve(sut, in: doubles)

        sut.dismissError()

        #expect(sut.errorMessage == nil)
        await waitUntil { doubles.delayProvider.cancelledWaitsCount == 1 }
        #expect(doubles.delayProvider.cancelledWaitsCount == 1)
    }

    @Test("The error hides itself once its display time is over")
    func errorHidesAfterDisplayTime() async {
        let (sut, doubles) = makeSUT(results: [.failure(CollectiblesPackPurchaseError.paymentTimedOut)])
        let messages = PublisherRecorder(sut.$errorMessage.removeDuplicates().eraseToAnyPublisher())
        await waitUntil { sut.buttonState == .approve }
        await approve(sut, in: doubles)

        await waitUntil { doubles.delayProvider.waits.count == 1 }
        #expect(sut.errorMessage == Localization.commonSomethingWentWrong)

        doubles.delayProvider.releaseWaits()
        await waitUntil { sut.errorMessage == nil }

        let expectedMessages: [String?] = [nil, Localization.commonSomethingWentWrong, nil]
        #expect(messages.values == expectedMessages)
    }

    @Test("A later error leaves a single hide timer, the one of the message on screen")
    func laterErrorKeepsSingleHideTimer() async {
        let results: [Result<CollectiblesPackPurchaseResult, any Error>] = [
            .failure(CollectiblesPackPurchaseError.paymentTimedOut),
            .failure(CollectiblesPackPurchaseError.paymentTimedOut),
        ]
        let (sut, doubles) = makeSUT(results: results)
        let messages = PublisherRecorder(sut.$errorMessage.removeDuplicates().eraseToAnyPublisher())
        await waitUntil { sut.buttonState == .approve }
        await approve(sut, in: doubles)

        await approve(sut, in: doubles)
        await waitUntil { doubles.delayProvider.waits.count == 2 }
        await waitUntil { doubles.delayProvider.cancelledWaitsCount == 1 }

        #expect(doubles.delayProvider.cancelledWaitsCount == 1)
        #expect(sut.errorMessage == Localization.commonSomethingWentWrong)

        doubles.delayProvider.releaseWaits()
        await waitUntil { sut.errorMessage == nil }

        let message = Localization.commonSomethingWentWrong
        let expectedMessages: [String?] = [nil, message, nil, message, nil]
        #expect(messages.values == expectedMessages)
    }

    @Test("Approving again hides the error of the previous attempt at once")
    func approvingAgainHidesPreviousError() async {
        let results: [Result<CollectiblesPackPurchaseResult, any Error>] = [
            .failure(CollectiblesPackPurchaseError.paymentTimedOut),
            .success(.wonCard(Self.wonCard)),
        ]
        let (sut, doubles) = makeSUT(results: results)
        await waitUntil { sut.buttonState == .approve }
        await approve(sut, in: doubles)
        #expect(sut.errorMessage != nil)

        sut.approve()
        #expect(sut.errorMessage == nil)

        await waitUntil { doubles.balanceRefresher.callsCount == 2 }
        #expect(doubles.routable.revealCards.count == 1)
    }
}

// MARK: - Arguments

extension CollectiblesConfirmOrderViewModelTests {
    enum SheetButton: CaseIterable, Sendable {
        case primary
        case secondary
    }

    nonisolated static let isSystemSheetAvailable = ProcessInfo.processInfo.isOperatingSystemAtLeast(
        OperatingSystemVersion(majorVersion: 26, minorVersion: 0, patchVersion: 0)
    )

    nonisolated static let balanceArguments: [(balance: TokenBalanceType, expected: SUT.ButtonState)] = [
        (balance: .loaded(Constants.total), expected: .approve),
        (balance: .loaded(Constants.total - 1), expected: .notEnoughFunds),
        (balance: .loading(nil), expected: .balanceLoading),
        (balance: .failure(nil), expected: .balanceUnavailable),
        (balance: .empty(.noData), expected: .balanceUnavailable),
    ]

    nonisolated static let notApprovableArguments: [(balance: TokenBalanceType, state: SUT.ButtonState)] = [
        (balance: .loaded(Constants.total - 1), state: .notEnoughFunds),
        (balance: .loading(nil), state: .balanceLoading),
        (balance: .failure(nil), state: .balanceUnavailable),
    ]

    nonisolated static let retryArguments: [(balance: TokenBalanceType, state: SUT.ButtonState, refreshes: Int)] = [
        (balance: .failure(nil), state: .balanceUnavailable, refreshes: 1),
        (balance: .loaded(Constants.total), state: .approve, refreshes: 0),
    ]

    nonisolated static let unfinishedBalances: [TokenBalanceType] = [.loaded(0), .failure(nil), .loading(nil)]

    nonisolated static let colorSchemes: [ColorScheme] = [.dark, .light]

    nonisolated static let unopenedErrors: [CollectiblesPackPurchaseError] = [
        .packUnopened,
        .openFailed,
        .prizeNotDelivered,
    ]

    nonisolated static let cardImageArguments: [(backImageURL: URL?, expected: [URL])] = [
        (backImageURL: Constants.backImageURL, expected: [Constants.frontImageURL, Constants.backImageURL]),
        (backImageURL: nil, expected: [Constants.frontImageURL]),
    ]

    nonisolated static let genericFailures: [any Error] = [
        CollectiblesPackPurchaseError.paymentTimedOut,
        CollectiblesPackPurchaseError.paymentFailed(.manuallyBuybacked),
        CollectiblesPackPurchaseError.accountNotReady,
        CollectiblesPackPurchaseError.invalidPrice,
        CollectiblesPackPurchaseError.anotherPurchaseInProgress,
        URLError(.timedOut),
    ]
}

// MARK: - Helpers

private extension CollectiblesConfirmOrderViewModelTests {
    struct Doubles {
        let interactor: PurchaseInteractorStub
        let preloader: RevealAssetsPreloaderSpy
        let routable: ConfirmOrderRoutableSpy
        let balanceProvider: MutableTokenBalanceProviderMock
        let delayProvider: ManualDelayProviderStub
        let balanceRefresher: BalanceRefreshSpy
    }

    enum Constants {
        static let machineID = "pokemon_50"
        static let machineName = "Elite pack"
        static let price: Decimal = 50
        static let platformFee: Decimal = 1
        static let total: Decimal = 51
        static let buybackAmount: Decimal = 35.6
        static let artworkURL = URL(string: "https://example.com/pack.png")
        static let frontImageURL = URL(string: "https://example.com/front.png")!
        static let backImageURL = URL(string: "https://example.com/back.png")!
        static let darkVideoURL = URL(filePath: "/media/dark.mp4")
        static let lightVideoURL = URL(filePath: "/media/light.mp4")
        static let skipAudioURL = URL(filePath: "/media/skip.m4a")
    }

    nonisolated static var ticker: String {
        CollectiblesChainEnvironment.usdcTokenItem.currencySymbol
    }

    nonisolated static let wonCard = wonCard(backImageURL: Constants.backImageURL)

    nonisolated static func wonCard(backImageURL: URL?) -> CollectiblesWonCard {
        CollectiblesWonCard(
            nftAddress: "nft-1",
            imageFrontURL: Constants.frontImageURL,
            imageBackURL: backImageURL,
            gradingCompany: "PSA",
            grade: "GEM-MT 10",
            gradingID: "63181346",
            rarity: .rare,
            year: "2005",
            set: nil,
            serialNumber: nil,
            insuredValue: 49
        )
    }

    static func makeRevealViewModel() -> CollectiblesPackRevealViewModel {
        CollectiblesPackRevealViewModel(
            darkVideoURL: Constants.darkVideoURL,
            lightVideoURL: Constants.lightVideoURL,
            wonCard: wonCard,
            player: RevealPlayerStub(),
            offerProvider: BuybackOfferProviderStub(),
            buybackInteractor: BuybackInteractorStub(),
            signingActionButtonType: .requiredNFCInteraction,
            routable: nil,
            refreshBalance: {}
        )
    }

    static func machine() -> CollectiblesMachine {
        CollectiblesMachine(
            name: Constants.machineName,
            artworkURL: Constants.artworkURL,
            price: Constants.price,
            platformFee: Constants.platformFee,
            cardsPerPack: 1,
            buybackRate: Decimal(string: "0.85")!,
            expectedValue: Decimal(string: "53.95")!,
            tiers: []
        )
    }

    func makeSUT(
        balance: TokenBalanceType = .loaded(Constants.total),
        results: [Result<CollectiblesPackPurchaseResult, any Error>] = [.success(.wonCard(wonCard))],
        steps: [CollectiblesPackPurchaseStep] = [],
        hasUnfinishedPurchase: Bool = false,
        isTurboModeOn: Bool = false
    ) -> (SUT, Doubles) {
        let interactor = PurchaseInteractorStub(
            results: results,
            steps: steps,
            isPurchaseUnfinished: hasUnfinishedPurchase
        )
        let doubles = Doubles(
            interactor: interactor,
            preloader: RevealAssetsPreloaderSpy(),
            routable: ConfirmOrderRoutableSpy(),
            balanceProvider: MutableTokenBalanceProviderMock(initialState: balance),
            delayProvider: ManualDelayProviderStub(),
            balanceRefresher: BalanceRefreshSpy()
        )
        let sut = SUT(
            machineID: Constants.machineID,
            machine: Self.machine(),
            isTurboModeOn: isTurboModeOn,
            usdcBalanceProvider: doubles.balanceProvider,
            purchaseInteractor: doubles.interactor,
            routable: doubles.routable,
            revealAssetsPreloader: doubles.preloader,
            delayProvider: doubles.delayProvider,
            refreshBalance: { [balanceRefresher = doubles.balanceRefresher] in balanceRefresher.refresh() }
        )
        return (trackForMemoryLeaks(sut), doubles)
    }

    func approve(_ sut: SUT, in doubles: Doubles) async {
        let refreshes = doubles.balanceRefresher.callsCount
        sut.approve()
        await waitUntil { doubles.balanceRefresher.callsCount == refreshes + 1 }
    }

    func errorMessage(after error: CollectiblesPackPurchaseError) async -> String? {
        let (sut, doubles) = makeSUT(results: [.failure(error)])
        defer { sut.dismissError() }
        await waitUntil { sut.buttonState == .approve }
        await approve(sut, in: doubles)
        return sut.errorMessage
    }

    func tap(_ button: SheetButton, on sheet: CollectiblesInfoSheetViewModel) {
        switch button {
        case .primary: sheet.primary()
        case .secondary: sheet.secondary()
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

// MARK: - Stubs

private struct PurchaseRequest: Equatable {
    let machineID: String
    let price: Decimal
    let platformFee: Decimal
    let isTurboModeOn: Bool
}

@MainActor
private final class PurchaseInteractorStub: CollectiblesPackPurchaseInteractor {
    private(set) var purchases: [PurchaseRequest] = []

    private let steps: [CollectiblesPackPurchaseStep]
    private let isPurchaseUnfinished: Bool
    private var results: [Result<CollectiblesPackPurchaseResult, any Error>]

    init(
        results: [Result<CollectiblesPackPurchaseResult, any Error>],
        steps: [CollectiblesPackPurchaseStep],
        isPurchaseUnfinished: Bool
    ) {
        self.results = results
        self.steps = steps
        self.isPurchaseUnfinished = isPurchaseUnfinished
    }

    func hasUnfinishedPurchase(machineID: String) -> Bool {
        isPurchaseUnfinished
    }

    func purchase(
        machineID: String,
        price: Decimal,
        platformFee: Decimal,
        isTurboModeOn: Bool,
        onStep: @escaping (CollectiblesPackPurchaseStep) -> Void
    ) async throws -> CollectiblesPackPurchaseResult {
        purchases.append(
            PurchaseRequest(machineID: machineID, price: price, platformFee: platformFee, isTurboModeOn: isTurboModeOn)
        )
        steps.forEach(onStep)

        let result = results.count > 1 ? results.removeFirst() : results[0]
        return try result.get()
    }
}

@MainActor
private final class RevealAssetsPreloaderSpy: CollectiblesRevealAssetsPreloader {
    private(set) var preloadedColorSchemes: [ColorScheme] = []
    private(set) var prefetchedImageURLs: [[URL]] = []

    func preload(for colorScheme: ColorScheme) {
        preloadedColorSchemes.append(colorScheme)
    }

    func assets(prefetchingImages imageURLs: [URL]) async -> CollectiblesRevealAssets {
        prefetchedImageURLs.append(imageURLs)
        return CollectiblesRevealAssets(
            darkVideoURL: CollectiblesConfirmOrderViewModelTests.Constants.darkVideoURL,
            lightVideoURL: CollectiblesConfirmOrderViewModelTests.Constants.lightVideoURL,
            skipAudioURL: CollectiblesConfirmOrderViewModelTests.Constants.skipAudioURL
        )
    }
}

@MainActor
private final class RevealPlayerStub: CollectiblesRevealPlayer {
    var videoPlayerPublisher: AnyPublisher<AVPlayer?, Never> {
        Just(nil).eraseToAnyPublisher()
    }

    func play(videoURL: URL?) async throws -> CollectiblesRevealPlayerResult {
        CollectiblesRevealPlayerResult(isSkipped: false)
    }

    func skip() {}
}

private struct BuybackOfferProviderStub: CollectiblesBuybackOfferProvider {
    func load(nftAddress: String) async throws -> CollectiblesBuybackOffer? {
        nil
    }
}

private struct BuybackInteractorStub: CollectiblesBuybackInteractor {
    func sell(nftAddress: String, offer: CollectiblesBuybackOffer) async throws {}
}

private final class ManualDelayProviderStub: PollDelayProvider, Sendable {
    private let state = OSAllocatedUnfairLock(initialState: State())

    var waits: [TimeInterval] {
        state.withLock { $0.waits }
    }

    var cancelledWaitsCount: Int {
        state.withLock { $0.cancelledWaitsCount }
    }

    func wait(for seconds: TimeInterval) async throws {
        let id = state.withLock { state -> Int in
            state.nextID += 1
            return state.nextID
        }

        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                let isCancelled = state.withLock { state -> Bool in
                    state.waits.append(seconds)

                    guard !Task.isCancelled else { return true }

                    state.parked[id] = continuation
                    return false
                }

                if isCancelled {
                    continuation.resume(throwing: CancellationError())
                }
            }
        } onCancel: {
            let parked = state.withLock { state -> CheckedContinuation<Void, any Error>? in
                state.cancelledWaitsCount += 1
                return state.parked.removeValue(forKey: id)
            }

            parked?.resume(throwing: CancellationError())
        }
    }

    func releaseWaits() {
        let parked = state.withLock { state -> [CheckedContinuation<Void, any Error>] in
            defer { state.parked.removeAll() }
            return Array(state.parked.values)
        }

        parked.forEach { $0.resume() }
    }
}

private extension ManualDelayProviderStub {
    struct State {
        var nextID = 0
        var waits: [TimeInterval] = []
        var cancelledWaitsCount = 0
        var parked: [Int: CheckedContinuation<Void, any Error>] = [:]
    }
}

@MainActor
private final class ConfirmOrderRoutableSpy: CollectiblesConfirmOrderRoutable {
    private(set) var revealCards: [CollectiblesWonCard] = []
    private(set) var revealAssets: [CollectiblesRevealAssets] = []
    private(set) var returnToMachineCallsCount = 0
    private(set) var closePackFlowCallsCount = 0

    func openPackReveal(wonCard: CollectiblesWonCard, assets: CollectiblesRevealAssets) {
        revealCards.append(wonCard)
        revealAssets.append(assets)
    }

    func returnToMachine() {
        returnToMachineCallsCount += 1
    }

    func closePackFlow() {
        closePackFlowCallsCount += 1
    }
}

private final class BalanceRefreshSpy: Sendable {
    private let count = OSAllocatedUnfairLock(initialState: 0)

    var callsCount: Int {
        count.withLock { $0 }
    }

    func refresh() {
        count.withLock { $0 += 1 }
    }
}
