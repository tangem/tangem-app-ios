//
//  SwapDeeplinkWalletFallbackTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
import TangemExpress
import TangemFoundation
import TangemUI
@testable import Tangem

@Suite("Swap deeplink wallet fallback", .serialized)
@MainActor
struct SwapDeeplinkWalletFallbackTests {
    // MARK: - Main screen

    @Test("No user_wallet_id: swap opens on the selected wallet")
    func mainWithoutWalletId() async {
        let environment = InjectedEnvironment()

        await environment.run {
            let spy = MainRoutableSpy()
            let handler = MainCoordinator.MainNavigationActionHandler()
            handler.coordinator = spy

            let handled = handler.didReceiveIncomingAction(.navigation(makeAction(params: .empty)))

            #expect(handled)
            #expect(spy.swapParameters?.sourceUserWalletId == InjectedEnvironment.selectedWalletId)
        }
    }

    @Test("Unknown user_wallet_id: swap still opens, on the selected wallet")
    func mainWithUnknownWalletId() async {
        let environment = InjectedEnvironment()

        await environment.run {
            let spy = MainRoutableSpy()
            let handler = MainCoordinator.MainNavigationActionHandler()
            handler.coordinator = spy

            let params = DeeplinkNavigationAction.Params(userWalletId: InjectedEnvironment.unknownWalletId)
            let handled = handler.didReceiveIncomingAction(.navigation(makeAction(params: params)))

            #expect(handled)
            #expect(spy.swapParameters?.sourceUserWalletId == InjectedEnvironment.selectedWalletId)
        }
    }

    @Test("Known user_wallet_id: the requested FROM is preselected")
    func mainKnownWalletIdPreselectsRequestedToken() async {
        let environment = InjectedEnvironment()

        await environment.run {
            let spy = MainRoutableSpy()
            let handler = MainCoordinator.MainNavigationActionHandler()
            handler.coordinator = spy

            let handled = handler.didReceiveIncomingAction(.navigation(makeAction(params: makeRequestedPairParams(userWalletId: InjectedEnvironment.selectedWalletId))))

            #expect(handled)
            #expect(spy.swapParameters?.sourceUserWalletId == InjectedEnvironment.selectedWalletId)
            #expect(spy.swapParameters?.isPairDeferred == false)
        }
    }

    @Test("Unknown user_wallet_id: the requested FROM is dropped along with the wallet")
    func mainUnknownWalletIdDropsPreselection() async {
        let environment = InjectedEnvironment()

        await environment.run {
            let spy = MainRoutableSpy()
            let handler = MainCoordinator.MainNavigationActionHandler()
            handler.coordinator = spy

            let handled = handler.didReceiveIncomingAction(.navigation(makeAction(params: makeRequestedPairParams(userWalletId: InjectedEnvironment.unknownWalletId))))

            #expect(handled)
            #expect(spy.swapParameters?.sourceUserWalletId == InjectedEnvironment.selectedWalletId)
            #expect(spy.swapParameters?.isPairDeferred == true)
        }
    }

    @Test("Unusable FROM side and amount: swap still opens on the selected wallet")
    func mainWithUnusableParamsOpensSwap() async {
        let environment = InjectedEnvironment()

        await environment.run {
            let spy = MainRoutableSpy()
            let handler = MainCoordinator.MainNavigationActionHandler()
            handler.coordinator = spy

            let handled = handler.didReceiveIncomingAction(.navigation(makeAction(params: makeUnusableParams())))

            #expect(handled)
            #expect(spy.swapParameters?.sourceUserWalletId == InjectedEnvironment.selectedWalletId)
        }
    }

    // MARK: - Token details / staking screen

    @Test("Unknown user_wallet_id: swap opens on this screen's wallet, without preselection")
    func promotionUnknownWalletIdOpensOnThisScreensWallet() async {
        let environment = InjectedEnvironment()

        await environment.run {
            let spy = PromotionDeeplinkRoutableSpy()
            let handler = PromotionDeeplinkHandler(
                coordinator: spy,
                walletModel: CommonWalletModel.mockETH,
                userWalletInfo: environment.otherWallet.userWalletInfo
            )

            let handled = handler.didReceiveIncomingAction(.navigation(makeAction(params: makeRequestedPairParams(userWalletId: InjectedEnvironment.unknownWalletId))))

            #expect(handled)
            #expect(spy.swapParameters?.sourceUserWalletId == InjectedEnvironment.otherWalletId)
            #expect(spy.swapParameters?.isPairDeferred == true)
        }
    }

    @Test("Unusable FROM side and amount: swap still opens on this screen's wallet")
    func promotionWithUnusableParamsOpensSwap() async {
        let environment = InjectedEnvironment()

        await environment.run {
            let spy = PromotionDeeplinkRoutableSpy()
            let handler = PromotionDeeplinkHandler(
                coordinator: spy,
                walletModel: CommonWalletModel.mockETH,
                userWalletInfo: environment.otherWallet.userWalletInfo
            )

            let handled = handler.didReceiveIncomingAction(.navigation(makeAction(params: makeUnusableParams())))

            #expect(handled)
            #expect(spy.swapParameters?.sourceUserWalletId == InjectedEnvironment.otherWalletId)
        }
    }

    @Test("Another wallet's user_wallet_id: swap opens on that wallet instead of being passed on")
    func promotionAnotherWalletIdOpensThatWallet() async {
        let environment = InjectedEnvironment()

        await environment.run {
            let spy = PromotionDeeplinkRoutableSpy()
            let handler = PromotionDeeplinkHandler(
                coordinator: spy,
                walletModel: CommonWalletModel.mockETH,
                userWalletInfo: environment.otherWallet.userWalletInfo
            )

            let params = DeeplinkNavigationAction.Params(userWalletId: InjectedEnvironment.selectedWalletId)
            let handled = handler.didReceiveIncomingAction(.navigation(makeAction(params: params)))

            #expect(handled)
            #expect(spy.swapParameters?.sourceUserWalletId == InjectedEnvironment.selectedWalletId)
        }
    }
}

// MARK: - Fixtures

private extension SwapDeeplinkWalletFallbackTests {
    func makeAction(params: DeeplinkNavigationAction.Params) -> DeeplinkNavigationAction {
        DeeplinkNavigationAction(destination: .swap, params: params, deeplinkString: "tangem://swap")
    }

    /// The link reported in [REDACTED_INFO]: nothing on the FROM side resolves and the amount isn't a number,
    /// while the TO side is well-formed.
    func makeUnusableParams() -> DeeplinkNavigationAction.Params {
        DeeplinkNavigationAction.Params(
            swapFromTokenId: "???",
            swapFromNetworkId: "does not exist",
            swapToTokenId: "ethereum",
            swapToNetworkId: "ethereum",
            swapFromAmount: "abc"
        )
    }

    /// A FROM side naming the only token the stubbed wallets hold, so a resolved preselection is
    /// distinguishable from the best-effort fallback.
    func makeRequestedPairParams(userWalletId: String) -> DeeplinkNavigationAction.Params {
        let tokenItem = CommonWalletModel.mockETH.tokenItem

        return DeeplinkNavigationAction.Params(
            userWalletId: userWalletId,
            swapFromTokenId: tokenItem.id?.lowercased(),
            swapFromNetworkId: tokenItem.blockchain.networkId.lowercased()
        )
    }
}

// MARK: - InjectedEnvironment

/// Two wallets in the repository — the selected one and another — plus a swap-available express
/// provider, restored after the body runs.
private final class InjectedEnvironment {
    static let selectedWalletId = UserWalletId(value: Data("selected-wallet".utf8)).stringValue
    static let otherWalletId = UserWalletId(value: Data("other-wallet".utf8)).stringValue
    static let unknownWalletId = UserWalletId(value: Data("unknown-wallet".utf8)).stringValue

    let selectedWallet = CampaignUserWalletModelStub(walletIdSeed: "selected-wallet")
    let otherWallet = CampaignUserWalletModelStub(walletIdSeed: "other-wallet")

    func run(_ body: () -> Void) async {
        await InjectedDependenciesIsolation.shared.run {
            let previousRepository = InjectedValues[\.userWalletRepository]
            let previousExpressProvider = InjectedValues[\.expressAvailabilityProvider]

            let repository = FakeUserWalletRepository(models: [selectedWallet, otherWallet])
            repository.selectedModel = selectedWallet
            InjectedValues[\.userWalletRepository] = repository
            InjectedValues[\.expressAvailabilityProvider] = SwapAvailableExpressProviderStub()

            defer {
                InjectedValues[\.userWalletRepository] = previousRepository
                InjectedValues[\.expressAvailabilityProvider] = previousExpressProvider
            }

            body()
        }
    }
}

// MARK: - Stubs and spies

private final class SwapAvailableExpressProviderStub: ExpressAvailabilityProvider {
    var hasCache: Bool { true }
    var availabilityDidChangePublisher: AnyPublisher<Void, Never> { Empty().eraseToAnyPublisher() }
    var expressAvailabilityUpdateStateValue: ExpressAvailabilityUpdateState { .updated }
    var expressAvailabilityUpdateState: AnyPublisher<ExpressAvailabilityUpdateState, Never> { .just(output: .updated) }

    func swapState(for tokenItem: TokenItem) -> TokenItemExpressState { .available }
    func onrampState(for tokenItem: TokenItem) -> TokenItemExpressState { .unavailable }
    func canSwap(tokenItem: TokenItem) -> Bool { true }
    func canOnramp(tokenItem: TokenItem) -> Bool { false }
    func updateExpressAvailability(for items: [TokenItem], forceReload: Bool, userWalletId: String) {}
}

private final class MainRoutableSpy: MainRoutable {
    private(set) var openedDeepLinks: [MainCoordinator.DeepLinkDestination] = []

    var swapParameters: PredefinedSwapParameters? {
        openedDeepLinks.compactMap { destination in
            guard case .swap(let parameters) = destination else { return nil }
            return parameters
        }.first
    }

    func openDeepLink(_ deepLink: MainCoordinator.DeepLinkDestination) {
        openedDeepLinks.append(deepLink)
    }

    func openCampaignIfNeeded(campaignId: String?) -> Bool { false }
    func beginHandlingIncomingActions() {}
    func resignHandlingIncomingActions() {}
    func openDetails() {}
    func openMail(with dataCollector: EmailDataCollector, emailType: EmailType, recipient: String) {}
    func openOnboardingModal(with options: OnboardingCoordinator.Options) {}
    func openScanCardManual() {}
    func openPushNotificationsAuthorization() {}
    func openQRScan() {}
    func popToRoot() {}
    func show(floatingSheetViewModel: some FloatingSheetContentViewModel) {}
    func show(toast: Toast<WarningToast>) {}
}

private final class PromotionDeeplinkRoutableSpy: PromotionDeeplinkRoutable {
    private(set) var swapParameters: PredefinedSwapParameters?

    func openSwap(parameters: PredefinedSwapParameters) {
        swapParameters = parameters
    }

    func openOnramp(input: SendInput, parameters: PredefinedOnrampParameters) {}
    func openInSafari(url: URL) {}
}

// MARK: - Observables

private extension PredefinedSwapParameters {
    /// Which wallet the swap screen was opened for.
    var sourceUserWalletId: String? {
        switch self {
        case .from(let source, _, _, _):
            return source.userWalletInfo.id.stringValue
        case .to(let receive, _, _):
            return receive.userWalletInfo.id.stringValue
        }
    }

    /// `true` for the best-effort fallback, whose source is a guess a resolver settles later —
    /// as opposed to a source that came from the link's own parameters.
    var isPairDeferred: Bool {
        switch self {
        case .from(_, .deferred, _, _):
            return true
        case .from, .to:
            return false
        }
    }
}
