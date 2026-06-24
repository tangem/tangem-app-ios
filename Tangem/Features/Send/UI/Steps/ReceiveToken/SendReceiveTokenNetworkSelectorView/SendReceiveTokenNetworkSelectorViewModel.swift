//
//  SendReceiveTokenNetworkSelectorViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation
import TangemExpress
import TangemUI
import TangemLocalization

protocol SendReceiveTokenNetworkSelectorViewRoutable: AnyObject {
    func dismissNetworkSelector(isSelected: Bool)
    func openManualSwap(option: SwapNavigatingDismissOption)
    func openAddTokenFlow(
        inputData: ExpressAddTokenInputData,
        makeSwapOption: @escaping (TokenItem) -> SwapNavigatingDismissOption
    )
}

class SendReceiveTokenNetworkSelectorViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Injected(\.swapRepository)
    private var swapRepository: SwapRepository

    @Published var notification: NotificationViewInput?
    @Published var state: ViewState = .loading

    var headerTitle: String {
        if case .networks = state {
            return Localization.commonChooseNetwork
        }

        return ""
    }

    var notSupportedTitle: String {
        // It's should be the same token name in all token items
        if let tokenName = networks.first?.name {
            return Localization.expressSwapNotSupportedTitle(tokenName)
        }

        return Localization.commonError
    }

    private weak var sourceTokenInput: SendSourceTokenInput?
    private weak var receiveTokenOutput: SendReceiveTokenOutput?
    private let networks: [TokenItem]
    private let coin: CoinModel
    private let userWalletInfo: UserWalletInfo
    private let isAvailabilityCheckEnabled: Bool
    private let analyticsLogger: SendReceiveTokensListAnalyticsLogger

    private weak var router: SendReceiveTokenNetworkSelectorViewRoutable?

    private var loadTask: Task<Void, Never>?

    init(
        sourceTokenInput: SendSourceTokenInput,
        receiveTokenOutput: SendReceiveTokenOutput,
        networks: [TokenItem],
        coin: CoinModel,
        userWalletInfo: UserWalletInfo,
        isAvailabilityCheckEnabled: Bool,
        analyticsLogger: SendReceiveTokensListAnalyticsLogger,
        router: SendReceiveTokenNetworkSelectorViewRoutable
    ) {
        self.sourceTokenInput = sourceTokenInput
        self.receiveTokenOutput = receiveTokenOutput
        self.networks = networks
        self.coin = coin
        self.userWalletInfo = userWalletInfo
        self.isAvailabilityCheckEnabled = isAvailabilityCheckEnabled
        self.analyticsLogger = analyticsLogger
        self.router = router

        load()
        setupNotification()
    }

    func dismiss() {
        loadTask?.cancel()
        router?.dismissNetworkSelector(isSelected: false)
    }

    private func setupNotification() {
        notification = NotificationsFactory().buildNotificationInput(
            for: SendReceiveTokensListNotification.irreversibleLossNotification
        )
    }

    private func load() {
        loadTask = runTask(in: self) { viewModel in
            do {
                // The pairs cache can under-report networks, so only a positive
                // verdict is trusted here; otherwise pairs are loaded from scratch
                let cachedAvailability = try? await viewModel.classify()

                if case .sendWithSwap(let items) = cachedAvailability {
                    await runOnMain { viewModel.state = .networks(items) }
                    return
                }

                // We use the minimum loading time here
                // Otherwise the bottom sheet is jumping
                let availability = try await runTask(withMinimumTime: 1) {
                    try await viewModel.loadAvailability()
                }.value

                switch availability {
                case .sendWithSwap(let items):
                    await runOnMain { viewModel.state = .networks(items) }
                case .swapOnly(let items):
                    viewModel.analyticsLogger.logSendSwapAvailable(token: viewModel.coin.symbol)
                    let viewData = viewModel.makeSwapRequiredViewData(swapableReceiveTokenItems: items)
                    await runOnMain { viewModel.state = .swapRequired(viewData) }
                }
            } catch Error.supportedNetworksIsEmpty {
                viewModel.analyticsLogger.logSendSwapCantSwapThisToken(token: viewModel.coin.symbol)
                await runOnMain { viewModel.state = .notSupported(text: Localization.expressSwapNotSupportedText) }
            } catch {
                await runOnMain { viewModel.state = .notSupported(text: error.localizedDescription) }
            }
        }
    }

    private func loadAvailability() async throws -> NetworksAvailability {
        guard let sourceToken = sourceTokenInput?.sourceToken.value else {
            throw CommonError.objectReleased
        }

        try await swapRepository.updatePairs(
            from: sourceToken.tokenItem.expressCurrency,
            to: networks.map(\.expressCurrency),
            userWalletInfo: userWalletInfo
        )

        guard let availability = try await classify() else {
            throw Error.supportedNetworksIsEmpty
        }

        return availability
    }

    /// Splits the coin's networks by provider support: a network is usable in Send-with-Swap
    /// only when its pair has at least one provider passing the source token's filter.
    /// Returns `nil` when nothing is usable even in the regular swap.
    private func classify() async throws -> NetworksAvailability? {
        guard let sourceToken = sourceTokenInput?.sourceToken.value else {
            throw CommonError.objectReleased
        }

        let pairs = await swapRepository.getPairs(from: sourceToken.tokenItem.expressCurrency)

        // A (source, destination) can be cached as several `ExpressPair` values with different
        // provider lists (ExpressPair's `Hashable` includes `providers`), so merge providers
        // across every pair matching a network instead of relying on an arbitrary `first`.
        let networksWithProviders: [(item: TokenItem, pairProviders: [ExpressPairProvider])] = networks.compactMap { network in
            let pairProviders = pairs
                .filter { $0.destination == network.expressCurrency.asCurrency }
                .flatMap(\.providers)

            return pairProviders.isEmpty ? nil : (network, pairProviders)
        }

        guard !networksWithProviders.isEmpty else {
            return nil
        }

        // Without the availability check, any network with a pair is selectable (legacy behavior)
        guard isAvailabilityCheckEnabled else {
            return .sendWithSwap(networksWithProviders.map { mapToSendReceiveTokenNetworkSelectorNetworkViewData(tokenItem: $0.item) })
        }

        guard let swapableSourceToken = sourceToken as? SendWithSwapToken else {
            return nil
        }

        let providers = try await swapRepository.providers(userWalletInfo: userWalletInfo)
        let providersById = providers.reduce(into: [:]) { $0[$1.id] = $1 }

        func hasProvider(in pairProviders: [ExpressPairProvider], passing filter: SupportedProvidersFilter) -> Bool {
            pairProviders.contains { pairProvider in
                providersById[pairProvider.id].map { filter.isSupported(provider: $0) } ?? false
            }
        }

        let sendWithSwapItems = networksWithProviders
            .filter { hasProvider(in: $0.pairProviders, passing: swapableSourceToken.supportedProvidersFilter) }
            .map { mapToSendReceiveTokenNetworkSelectorNetworkViewData(tokenItem: $0.item) }

        if !sendWithSwapItems.isEmpty {
            return .sendWithSwap(sendWithSwapItems)
        }

        // Suggesting the manual swap makes sense only when the source token can be swapped at all
        guard swapableSourceToken.swapAvailabilityProvider.isSwapAvailable else {
            return nil
        }

        let swapOnlyItems = networksWithProviders
            .filter { hasProvider(in: $0.pairProviders, passing: .swap) }
            .map(\.item)

        return swapOnlyItems.isEmpty ? nil : .swapOnly(swapOnlyItems)
    }

    private func makeSwapRequiredViewData(swapableReceiveTokenItems: [TokenItem]) -> SendReceiveTokenSwapRequiredViewData {
        SendReceiveTokenSwapRequiredViewData(
            iconURL: IconURLBuilder().tokenIconURL(id: coin.id, size: .large),
            title: Localization.expressSendWithSwapNotSupportedTitle(coin.name),
            subtitle: Localization.expressSendWithSwapNotSupportedText,
            buttonTitle: Localization.expressSendWithSwapNotSupportedButton
        ) { [weak self] in
            self?.userDidRequestManualSwap(swapableReceiveTokenItems: swapableReceiveTokenItems)
        }
    }

    private func mapToSendReceiveTokenNetworkSelectorNetworkViewData(tokenItem: TokenItem) -> SendReceiveTokenNetworkSelectorNetworkViewData {
        SendReceiveTokenNetworkSelectorNetworkViewData(
            id: tokenItem.blockchain.networkId,
            iconURL: IconURLBuilder().tokenIconURL(id: tokenItem.blockchain.coinId, size: .large),
            name: tokenItem.blockchain.displayName,
            network: tokenItem.contractName,
            isMainNetwork: tokenItem.isBlockchain
        ) { [weak self] in
            self?.userDidSelect(tokenItem: tokenItem)
        }
    }

    private func userDidSelect(tokenItem: TokenItem) {
        guard SendReceiveTokenFilter.isSupported(receiveTokenBlockchain: tokenItem.blockchain) else {
            state = .notSupported(text: Localization.expressSwapNotSupportedText)
            return
        }

        receiveTokenOutput?.userDidRequestSelect(receiveTokenItem: tokenItem) { [weak self] selected in
            self?.analyticsLogger.logTokenChosen(token: tokenItem)
            self?.router?.dismissNetworkSelector(isSelected: selected)
        }
    }

    private func userDidRequestManualSwap(swapableReceiveTokenItems: [TokenItem]) {
        guard let sourceTokenItem = sourceTokenInput?.sourceToken.value?.tokenItem else {
            return
        }

        analyticsLogger.logSendSwapAvailableClicked(token: coin.symbol)

        let userWalletId = userWalletInfo.id
        let makeSwapOption = { (receiveTokenItem: TokenItem) in
            SwapNavigatingDismissOption(
                userWalletId: userWalletId,
                sourceTokenItem: sourceTokenItem,
                receiveTokenItem: receiveTokenItem
            )
        }

        // A held network lets the swap open with both sides prefilled
        let heldTokenItem = swapableReceiveTokenItems.first { tokenItem in
            (try? WalletModelFinder.findWalletModel(userWalletId: userWalletId, tokenItem: tokenItem)) != nil
        }

        if let heldTokenItem {
            router?.openManualSwap(option: makeSwapOption(heldTokenItem))
            return
        }

        let inputData = ExpressAddTokenInputData(
            coinId: coin.id,
            coinName: coin.name,
            coinSymbol: coin.symbol,
            networks: swapableReceiveTokenItems.map { tokenItem in
                NetworkModel(
                    networkId: tokenItem.blockchain.networkId,
                    contractAddress: tokenItem.token?.contractAddress,
                    decimalCount: tokenItem.token?.decimalCount
                )
            },
            userHasSearchedDuringThisSession: false
        )

        router?.openAddTokenFlow(inputData: inputData, makeSwapOption: makeSwapOption)
    }
}

extension SendReceiveTokenNetworkSelectorViewModel {
    enum ViewState: Equatable {
        case loading
        case networks([SendReceiveTokenNetworkSelectorNetworkViewData])
        case swapRequired(SendReceiveTokenSwapRequiredViewData)
        case notSupported(text: String)
    }

    enum Error: LocalizedError {
        case supportedNetworksIsEmpty
    }

    private enum NetworksAvailability {
        case sendWithSwap([SendReceiveTokenNetworkSelectorNetworkViewData])
        case swapOnly([TokenItem])
    }
}
