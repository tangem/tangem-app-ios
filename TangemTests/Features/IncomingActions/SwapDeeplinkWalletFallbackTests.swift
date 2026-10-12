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
    // MARK: - A screen with no wallet of its own

    @Test("No user_wallet_id: swap opens on the selected wallet")
    func withoutWalletId() async {
        let environment = InjectedEnvironment()

        await environment.run {
            let parameters = SwapDeeplink().makeParameters()

            #expect(parameters?.userWalletId.stringValue == InjectedEnvironment.selectedWalletId)
        }
    }

    @Test("Unknown user_wallet_id: swap still opens, on the selected wallet")
    func withUnknownWalletId() async {
        let environment = InjectedEnvironment()

        await environment.run {
            let parameters = SwapDeeplink(userWalletId: InjectedEnvironment.unknownWalletId).makeParameters()

            #expect(parameters?.userWalletId.stringValue == InjectedEnvironment.selectedWalletId)
        }
    }

    @Test("Known user_wallet_id: the requested FROM is preselected")
    func knownWalletIdPreselectsRequestedToken() async {
        let environment = InjectedEnvironment()

        await environment.run {
            let parameters = makeRequestedPairDeeplink(userWalletId: InjectedEnvironment.selectedWalletId).makeParameters()

            #expect(parameters?.userWalletId.stringValue == InjectedEnvironment.selectedWalletId)
            #expect(parameters?.isPairDeferred == false)
        }
    }

    @Test("No user_wallet_id: the requested FROM is preselected on the selected wallet")
    func withoutWalletIdPreservesRequestedToken() async {
        let environment = InjectedEnvironment()

        await environment.run {
            let parameters = makeRequestedPairDeeplink(userWalletId: nil).makeParameters()

            #expect(parameters?.userWalletId.stringValue == InjectedEnvironment.selectedWalletId)
            #expect(parameters?.isPairDeferred == false)
        }
    }

    @Test("Unknown user_wallet_id: the requested FROM is dropped along with the wallet")
    func unknownWalletIdDropsPreselection() async {
        let environment = InjectedEnvironment()

        await environment.run {
            let parameters = makeRequestedPairDeeplink(userWalletId: InjectedEnvironment.unknownWalletId).makeParameters()

            #expect(parameters?.userWalletId.stringValue == InjectedEnvironment.selectedWalletId)
            #expect(parameters?.isPairDeferred == true)
        }
    }

    @Test("Unusable FROM side and amount: swap still opens on the selected wallet")
    func unusableParamsStillOpenSwap() async {
        let environment = InjectedEnvironment()

        await environment.run {
            let parameters = makeUnusableDeeplink().makeParameters()

            #expect(parameters?.userWalletId.stringValue == InjectedEnvironment.selectedWalletId)
        }
    }

    // MARK: - Main screen

    @Test("Unknown user_wallet_id: the main screen opens swap on the selected wallet")
    func mainScreenUnknownWalletIdOpensSelectedWallet() async {
        let environment = InjectedEnvironment()

        await environment.run {
            let coordinator = MainScreenDeeplinkRoutableSpy()
            let responder = MainScreenDeeplinkResponder()
            responder.coordinator = coordinator

            InjectedValues[\.mainBottomSheetUIManager].setExpanded(false)

            let handled = responder.didReceiveIncomingAction(
                .navigation(.swap(makeRequestedPairDeeplink(userWalletId: InjectedEnvironment.unknownWalletId)))
            )

            #expect(handled)
            #expect(coordinator.swapParameters?.userWalletId.stringValue == InjectedEnvironment.selectedWalletId)
            #expect(coordinator.swapParameters?.isPairDeferred == true)
        }
    }

    // MARK: - Token details / staking screen

    @Test("Unknown user_wallet_id: swap opens on this screen's wallet, without preselection")
    func tokenScreenUnknownWalletIdOpensOnThisScreensWallet() async {
        let environment = InjectedEnvironment()

        await environment.run {
            let spy = TokenScreenDeeplinkRoutableSpy()
            let responder = makeResponder(spy: spy, environment: environment)

            let handled = responder.didReceiveIncomingAction(
                .navigation(.swap(makeRequestedPairDeeplink(userWalletId: InjectedEnvironment.unknownWalletId)))
            )

            #expect(handled)
            #expect(spy.swapParameters?.userWalletId.stringValue == InjectedEnvironment.otherWalletId)
            #expect(spy.swapParameters?.isPairDeferred == true)
        }
    }

    @Test("Unusable FROM side and amount: swap still opens on this screen's wallet")
    func tokenScreenUnusableParamsOpenSwap() async {
        let environment = InjectedEnvironment()

        await environment.run {
            let spy = TokenScreenDeeplinkRoutableSpy()
            let responder = makeResponder(spy: spy, environment: environment)

            let handled = responder.didReceiveIncomingAction(.navigation(.swap(makeUnusableDeeplink())))

            #expect(handled)
            #expect(spy.swapParameters?.userWalletId.stringValue == InjectedEnvironment.otherWalletId)
        }
    }

    @Test("Another wallet's user_wallet_id: swap opens on that wallet instead of being passed on")
    func tokenScreenAnotherWalletIdOpensThatWallet() async {
        let environment = InjectedEnvironment()

        await environment.run {
            let spy = TokenScreenDeeplinkRoutableSpy()
            let responder = makeResponder(spy: spy, environment: environment)

            let deeplink = SwapDeeplink(userWalletId: InjectedEnvironment.selectedWalletId)
            let handled = responder.didReceiveIncomingAction(.navigation(.swap(deeplink)))

            #expect(handled)
            #expect(spy.swapParameters?.userWalletId.stringValue == InjectedEnvironment.selectedWalletId)
        }
    }
}

// MARK: - Fixtures

private extension SwapDeeplinkWalletFallbackTests {
    /// The token screen of the wallet that isn't the selected one, so the two can be told apart.
    func makeResponder(spy: TokenScreenDeeplinkRoutableSpy, environment: InjectedEnvironment) -> TokenScreenDeeplinkResponder {
        TokenScreenDeeplinkResponder(
            coordinator: spy,
            walletModel: CommonWalletModel.mockETH,
            userWalletInfo: environment.otherWallet.userWalletInfo
        )
    }

    /// The link reported in [REDACTED_INFO]: nothing on the FROM side resolves and the amount isn't a number,
    /// while the TO side is well-formed.
    func makeUnusableDeeplink() -> SwapDeeplink {
        SwapDeeplink(
            fromTokenId: "???",
            fromNetworkId: "does not exist",
            toTokenId: "ethereum",
            toNetworkId: "ethereum",
            fromAmount: "abc"
        )
    }

    /// A FROM side naming the only token the stubbed wallets hold, so a resolved preselection is
    /// distinguishable from the best-effort fallback.
    func makeRequestedPairDeeplink(userWalletId: String?) -> SwapDeeplink {
        let tokenItem = CommonWalletModel.mockETH.tokenItem

        return SwapDeeplink(
            userWalletId: userWalletId,
            fromTokenId: tokenItem.id?.lowercased(),
            fromNetworkId: tokenItem.blockchain.networkId.lowercased()
        )
    }
}

// MARK: - InjectedEnvironment

/// Two wallets in the repository — the selected one and another — plus a swap-available express
/// provider, restored after the body runs.
final class InjectedEnvironment {
    static let selectedWalletId = UserWalletId(value: Data("selected-wallet".utf8)).stringValue
    static let otherWalletId = UserWalletId(value: Data("other-wallet".utf8)).stringValue
    static let unknownWalletId = UserWalletId(value: Data("unknown-wallet".utf8)).stringValue

    let selectedWallet = CampaignUserWalletModelStub(walletIdSeed: "selected-wallet")
    let otherWallet = CampaignUserWalletModelStub(walletIdSeed: "other-wallet")

    func run(_ body: () async -> Void) async {
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

            await body()
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

private final class TokenScreenDeeplinkRoutableSpy: TokenScreenDeeplinkRoutable {
    private(set) var swapParameters: PredefinedSwapParameters?

    func openSwap(parameters: PredefinedSwapParameters) {
        swapParameters = parameters
    }

    func openOnramp(input: SendInput, parameters: PredefinedOnrampParameters) {}
    func openInSafari(url: URL) {}
}

// MARK: - Observables

extension PredefinedSwapParameters {
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
