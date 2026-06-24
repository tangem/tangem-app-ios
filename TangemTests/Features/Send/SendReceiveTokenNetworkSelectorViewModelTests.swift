//
//  SendReceiveTokenNetworkSelectorViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine
import Foundation
import TangemFoundation
import Testing
@testable import TangemExpress
@testable import Tangem

@Suite("SendReceiveTokenNetworkSelectorViewModel", .serialized)
final class SendReceiveTokenNetworkSelectorViewModelTests {
    private let sourceToken = SendSourceTokenStub(blockchain: .ethereum(testnet: false))
    private let polygonItem = TokenItem.blockchain(.init(.polygon(testnet: false), derivationPath: nil))
    private let bscItem = TokenItem.blockchain(.init(.bsc(testnet: false), derivationPath: nil))
    private let coin = CoinModel(id: "coin-id", name: "Coin", symbol: "COIN", items: [])

    @Test("Networks with at least one S&S-capable provider are shown")
    func sendWithSwapCapableNetworkShown() async throws {
        let repository = SwapRepositoryConfigurableStub(
            pairs: [makePair(to: polygonItem, providerIds: ["cex"])],
            providers: [makeProvider(id: "cex", type: .cex, exchangeOnlyWithinSingleAddress: false)]
        )

        let state = try await loadedState(repository: repository, networks: [polygonItem])

        guard case .networks(let items) = state else {
            Issue.record("Expected .networks, got \(state)")
            return
        }
        #expect(items.count == 1)
    }

    @Test("Networks whose providers can't pay out to another address are filtered out")
    func deadEndNetworksAreFilteredOut() async throws {
        let repository = SwapRepositoryConfigurableStub(
            pairs: [
                makePair(to: polygonItem, providerIds: ["cex"]),
                makePair(to: bscItem, providerIds: ["singleAddressDex"]),
            ],
            providers: [
                makeProvider(id: "cex", type: .cex, exchangeOnlyWithinSingleAddress: false),
                makeProvider(id: "singleAddressDex", type: .dex, exchangeOnlyWithinSingleAddress: true),
            ]
        )

        let state = try await loadedState(repository: repository, networks: [polygonItem, bscItem])

        guard case .networks(let items) = state else {
            Issue.record("Expected .networks, got \(state)")
            return
        }
        #expect(items.count == 1)
        #expect(items.first?.id == polygonItem.blockchain.networkId)
    }

    @Test("Pair served only by single-address providers suggests the manual swap")
    func swapRequiredWhenOnlySingleAddressProviders() async throws {
        let repository = SwapRepositoryConfigurableStub(
            pairs: [makePair(to: polygonItem, providerIds: ["singleAddressDex"])],
            providers: [makeProvider(id: "singleAddressDex", type: .dex, exchangeOnlyWithinSingleAddress: true)]
        )

        let state = try await loadedState(repository: repository, networks: [polygonItem])

        guard case .swapRequired(let viewData) = state else {
            Issue.record("Expected .swapRequired, got \(state)")
            return
        }
        #expect(viewData.title.contains(coin.name))
    }

    @Test("Token without pairs is reported as not supported")
    func notSupportedWhenNoPairs() async throws {
        let repository = SwapRepositoryConfigurableStub(pairs: [], providers: [])

        let state = try await loadedState(repository: repository, networks: [polygonItem])

        guard case .notSupported = state else {
            Issue.record("Expected .notSupported, got \(state)")
            return
        }
    }

    @Test("Manual swap is not suggested when the source token can't be swapped")
    func notSupportedWhenSwapUnavailableForSourceToken() async throws {
        let repository = SwapRepositoryConfigurableStub(
            pairs: [makePair(to: polygonItem, providerIds: ["singleAddressDex"])],
            providers: [makeProvider(id: "singleAddressDex", type: .dex, exchangeOnlyWithinSingleAddress: true)]
        )

        let state = try await loadedState(
            repository: repository,
            networks: [polygonItem],
            isSwapAvailable: false
        )

        guard case .notSupported = state else {
            Issue.record("Expected .notSupported, got \(state)")
            return
        }
    }

    @Test("CEX-only filter classifies a DEX-only pair as requiring the manual swap")
    func cexFilterClassifiesDexOnlyPairAsSwapRequired() async throws {
        let repository = SwapRepositoryConfigurableStub(
            pairs: [makePair(to: polygonItem, providerIds: ["dex"])],
            providers: [makeProvider(id: "dex", type: .dex, exchangeOnlyWithinSingleAddress: false)]
        )

        let state = try await loadedState(
            repository: repository,
            networks: [polygonItem],
            supportedProvidersFilter: .cex
        )

        guard case .swapRequired = state else {
            Issue.record("Expected .swapRequired, got \(state)")
            return
        }
    }

    @Test("Empty pairs cache falls through to a fresh pairs load")
    func emptyCacheFallsThroughToLoad() async throws {
        let repository = SwapRepositoryConfigurableStub(
            pairs: [makePair(to: polygonItem, providerIds: ["cex"])],
            providers: [makeProvider(id: "cex", type: .cex, exchangeOnlyWithinSingleAddress: false)],
            pairsAvailableOnlyAfterUpdate: true
        )

        let state = try await loadedState(repository: repository, networks: [polygonItem])

        guard case .networks = state else {
            Issue.record("Expected .networks, got \(state)")
            return
        }
        let updatePairsCallsCount = await repository.updatePairsCallsCount
        #expect(updatePairsCallsCount == 1)
    }

    @Test("Providers are merged across duplicate cached pairs for the same destination")
    func providersMergedAcrossDuplicateCachedPairs() async throws {
        // Same source→destination cached twice with different provider lists — the capable
        // provider lives in the second entry, so an arbitrary `first` could miss it.
        let repository = SwapRepositoryConfigurableStub(
            pairs: [
                makePair(to: polygonItem, providerIds: ["singleAddressDex"]),
                makePair(to: polygonItem, providerIds: ["cex"]),
            ],
            providers: [
                makeProvider(id: "singleAddressDex", type: .dex, exchangeOnlyWithinSingleAddress: true),
                makeProvider(id: "cex", type: .cex, exchangeOnlyWithinSingleAddress: false),
            ]
        )

        let state = try await loadedState(repository: repository, networks: [polygonItem])

        guard case .networks(let items) = state else {
            Issue.record("Expected .networks, got \(state)")
            return
        }
        #expect(items.count == 1)
    }

    @Test("With the feature off, any network with a pair is selectable and no manual swap is suggested")
    func featureOffKeepsLegacyBehavior() async throws {
        // Single-address-only provider would be a manual-swap case with the feature on
        let repository = SwapRepositoryConfigurableStub(
            pairs: [makePair(to: polygonItem, providerIds: ["singleAddressDex"])],
            providers: [makeProvider(id: "singleAddressDex", type: .dex, exchangeOnlyWithinSingleAddress: true)]
        )

        let state = try await loadedState(repository: repository, networks: [polygonItem], featureEnabled: false)

        guard case .networks(let items) = state else {
            Issue.record("Expected .networks, got \(state)")
            return
        }
        #expect(items.count == 1)
    }
}

// MARK: - Helpers

private extension SendReceiveTokenNetworkSelectorViewModelTests {
    @MainActor
    func loadedState(
        repository: SwapRepositoryConfigurableStub,
        networks: [TokenItem],
        supportedProvidersFilter: SupportedProvidersFilter = .byDifferentAddressExchangeSupport,
        isSwapAvailable: Bool = true,
        featureEnabled: Bool = true,
        timeout: TimeInterval = 10
    ) async throws -> SendReceiveTokenNetworkSelectorViewModel.ViewState {
        let previousRepository = InjectedValues[\.swapRepository]
        InjectedValues[\.swapRepository] = repository
        defer { InjectedValues[\.swapRepository] = previousRepository }

        let swapableSourceToken = SendSwapableTokenStub(
            sourceToken: sourceToken,
            supportedProvidersFilter: supportedProvidersFilter,
            isSwapAvailable: isSwapAvailable
        )

        // The view model holds these weakly — keep them alive for the whole load
        let sourceTokenInput = SendSourceTokenInputStub(token: swapableSourceToken)
        let receiveTokenOutput = SendReceiveTokenOutputDummy()
        let router = SendReceiveTokenNetworkSelectorRoutableDummy()

        let viewModel = SendReceiveTokenNetworkSelectorViewModel(
            sourceTokenInput: sourceTokenInput,
            receiveTokenOutput: receiveTokenOutput,
            networks: networks,
            coin: coin,
            userWalletInfo: sourceToken.userWalletInfo,
            isAvailabilityCheckEnabled: featureEnabled,
            analyticsLogger: SendReceiveTokensListAnalyticsLoggerDummy(),
            router: router
        )

        defer { withExtendedLifetime((sourceTokenInput, receiveTokenOutput, router)) {} }

        let states = AsyncStream<SendReceiveTokenNetworkSelectorViewModel.ViewState> { continuation in
            let cancellable = viewModel.$state.sink { state in
                continuation.yield(state)
            }
            continuation.onTermination = { _ in cancellable.cancel() }
        }

        return try await Task.run(withTimeout: .seconds(timeout)) {
            for await state in states {
                if case .loading = state { continue }
                return state
            }

            throw TimeoutError()
        }
    }

    func makePair(to destination: TokenItem, providerIds: [ExpressProvider.Id]) -> ExpressPair {
        ExpressPair(
            source: sourceToken.tokenItem.expressCurrency.asCurrency,
            destination: destination.expressCurrency.asCurrency,
            providers: providerIds.map { ExpressPairProvider(id: $0, rates: [.float]) }
        )
    }

    func makeProvider(id: ExpressProvider.Id, type: ExpressProviderType, exchangeOnlyWithinSingleAddress: Bool) -> ExpressProvider {
        ExpressProvider(
            id: id,
            name: id,
            type: type,
            exchangeOnlyWithinSingleAddress: exchangeOnlyWithinSingleAddress,
            imageURL: nil,
            termsOfUse: nil,
            privacyPolicy: nil,
            recommended: nil,
            slippage: nil
        )
    }

    struct TimeoutError: Error {}
}

// MARK: - Stubs

private actor SwapRepositoryConfigurableStub: SwapRepository {
    private let pairsToReturn: [ExpressPair]
    private let providersToReturn: [ExpressProvider]
    private let pairsAvailableOnlyAfterUpdate: Bool

    private var updatePairsCalled = false
    private(set) var updatePairsCallsCount = 0

    init(
        pairs: [ExpressPair],
        providers: [ExpressProvider],
        pairsAvailableOnlyAfterUpdate: Bool = false
    ) {
        pairsToReturn = pairs
        providersToReturn = providers
        self.pairsAvailableOnlyAfterUpdate = pairsAvailableOnlyAfterUpdate
    }

    func updatePairs(from wallet: ExpressWalletCurrency, to currencies: [ExpressWalletCurrency], userWalletInfo: UserWalletInfo) async throws {
        updatePairsCallsCount += 1
        updatePairsCalled = true
    }

    func updatePairs(for wallet: ExpressWalletCurrency, userWalletInfo: UserWalletInfo) async throws {
        updatePairsCalled = true
    }

    func getPairs(from wallet: ExpressWalletCurrency) async -> [ExpressPair] {
        if pairsAvailableOnlyAfterUpdate, !updatePairsCalled {
            return []
        }

        return pairsToReturn.filter { $0.source == wallet.asCurrency }
    }

    func getPairs(to wallet: ExpressWalletCurrency) async -> [ExpressPair] {
        pairsToReturn.filter { $0.destination == wallet.asCurrency }
    }

    func providers(userWalletInfo: UserWalletInfo) async throws -> [ExpressProvider] {
        providersToReturn
    }

    // MARK: - ExpressRepository

    func updateProvidersIds(for pair: ExpressManagerSwappingPair) async throws {}

    func providers(for pair: ExpressManagerSwappingPair) async throws -> [ExpressProvider] {
        providersToReturn
    }

    func getAvailableProvidersIds(for pair: ExpressManagerSwappingPair, rateType: ExpressProviderRateType?) async -> [ExpressProvider.Id] {
        []
    }
}

private final class SendSwapableTokenStub: SendSwapableToken {
    private let inner: SendSourceTokenStub
    let supportedProvidersFilter: SupportedProvidersFilter
    let swapAvailabilityProvider: any SwapAvailabilityProvider

    init(
        sourceToken: SendSourceTokenStub,
        supportedProvidersFilter: SupportedProvidersFilter,
        isSwapAvailable: Bool
    ) {
        inner = sourceToken
        self.supportedProvidersFilter = supportedProvidersFilter
        swapAvailabilityProvider = SwapAvailabilityProviderStub(isSwapAvailable: isSwapAvailable)
    }

    // MARK: - SendSourceToken proxy

    var tokenItem: TokenItem { inner.tokenItem }
    var isCustom: Bool { inner.isCustom }
    var fiatItem: FiatItem { inner.fiatItem }
    var userWalletInfo: UserWalletInfo { inner.userWalletInfo }
    var id: WalletModelId { inner.id }
    var header: TokenHeader { inner.header }
    var feeTokenItem: TokenItem { inner.feeTokenItem }
    var defaultAddressString: String { inner.defaultAddressString }
    var availableBalanceProvider: TokenBalanceProvider { inner.availableBalanceProvider }
    var fiatAvailableBalanceProvider: TokenBalanceProvider { inner.fiatAvailableBalanceProvider }
    var allowanceService: (any AllowanceService)? { inner.allowanceService }
    var withdrawalNotificationProvider: WithdrawalNotificationProvider? { inner.withdrawalNotificationProvider }
    var emailDataCollectorBuilder: EmailDataCollectorBuilder { inner.emailDataCollectorBuilder }
    var transactionDispatcherProvider: any TransactionDispatcherProvider { inner.transactionDispatcherProvider }
    var accountModelAnalyticsProvider: (any AccountModelAnalyticsProviding)? { inner.accountModelAnalyticsProvider }
    var tangemIconProvider: any TangemIconProvider { inner.tangemIconProvider }
    var confirmTransactionPolicy: any ConfirmTransactionPolicy { inner.confirmTransactionPolicy }

    // MARK: - Unused in tests

    var isExemptFee: Bool { false }
    var sendYieldModuleHelper: SendYieldModuleHelper? { nil }
    var operationType: ExpressOperationType { .swapAndSend }
    var sendingRestrictionsProvider: any SendingRestrictionsProvider { fatalError("Unused in tests") }
    var receivingRestrictionsProvider: any ReceivingRestrictionsProvider { fatalError("Unused in tests") }
    var tokenFeeProvidersManagerProvider: any TokenFeeProvidersManagerProvider { fatalError("Unused in tests") }
    var tokenFeeProvidersManager: any TokenFeeProvidersManager { fatalError("Unused in tests") }
    var transactionValidator: any SendTransactionValidator { fatalError("Unused in tests") }
    var transactionCreator: any SendTransactionCreator { fatalError("Unused in tests") }
    var balanceProvider: any TangemExpress.BalanceProvider { fatalError("Unused in tests") }
    var analyticsLogger: any TangemExpress.AnalyticsLogger { fatalError("Unused in tests") }
    var providerTransactionValidator: any ExpressProviderTransactionValidator { fatalError("Unused in tests") }
}

private struct SwapAvailabilityProviderStub: SwapAvailabilityProvider {
    let isSwapAvailable: Bool
}

private final class SendSourceTokenInputStub: SendSourceTokenInput {
    private let token: SendSourceToken

    init(token: SendSourceToken) {
        self.token = token
    }

    var sourceToken: LoadingResult<SendSourceToken, any Error> { .success(token) }
    var sourceTokenPublisher: AnyPublisher<LoadingResult<SendSourceToken, any Error>, Never> {
        .just(output: .success(token))
    }
}

private final class SendReceiveTokenOutputDummy: SendReceiveTokenOutput {
    func userDidRequestSelect(receiveTokenItem: TokenItem, selected: @escaping (Bool) -> Void) {}
    func userDidRequestClearSelection() {}
}

private final class SendReceiveTokenNetworkSelectorRoutableDummy: SendReceiveTokenNetworkSelectorViewRoutable {
    func dismissNetworkSelector(isSelected: Bool) {}
    func openManualSwap(option: SwapNavigatingDismissOption) {}
    func openAddTokenFlow(inputData: ExpressAddTokenInputData, makeSwapOption: @escaping (TokenItem) -> SwapNavigatingDismissOption) {}
}

private struct SendReceiveTokensListAnalyticsLoggerDummy: SendReceiveTokensListAnalyticsLogger {
    func logSearchClicked() {}
    func logTokenSearched(coin: CoinModel, searchText: String?) {}
    func logTokenChosen(token: TokenItem) {}
    func logSendSwapCantSwapThisToken(token: String) {}
    func logSendSwapAvailable(token: String) {}
    func logSendSwapAvailableClicked(token: String) {}
}
