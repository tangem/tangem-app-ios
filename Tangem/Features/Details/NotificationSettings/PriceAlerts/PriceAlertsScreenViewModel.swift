//
//  PriceAlertsScreenViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemFoundation
import TangemLocalization
import TangemUI
import struct TangemUIUtils.AlertBinder

final class PriceAlertsScreenViewModel: ObservableObject {
    // MARK: - Injected

    @Injected(\.quotesRepository) private var quotesRepository: TokenQuotesRepository
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    // MARK: - Published

    @Published var showNotificationsEnabled: Bool = false
    @Published private(set) var showNotificationsRowViewModel: DefaultToggleRowViewModel?
    @Published private(set) var watchlistState: WatchlistState = .loading
    @Published var alert: AlertBinder?

    // MARK: - Private

    private let userWalletModel: UserWalletModel
    private weak var coordinator: PriceAlertsScreenRoutable?

    private let provider: PriceAlertsSubscriptionsProvider
    private let pushManager: UserWalletPushNotificationsManager

    /// Reuses the push-settings toggle flow (pending enable + system-permission handling) verbatim.
    private lazy var toggleInteractor = PushChannelToggleInteractor(
        userWalletPushNotificationsManager: pushManager,
        output: self
    )

    private let priceFormatter = MarketsTokenPriceFormatter()
    private let priceChangeUtility = PriceChangeUtility()
    private let iconURLBuilder = IconURLBuilder()

    /// Coin metadata (name/symbol) loaded per token id via CoinsList; quotes are kept separately
    /// because they update far more frequently through `quotesPublisher`.
    private var coinMetadataById: [PriceAlertTokenId: CoinsList.Coin] = [:]
    private var quotes: Quotes = [:]
    private var subscribedTokenIds: [PriceAlertTokenId] = []

    private var coinMetadataLoadTask: Task<Void, Never>?
    private var isLoadingCoinMetadata = false
    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(userWalletModel: UserWalletModel, coordinator: PriceAlertsScreenRoutable) {
        self.userWalletModel = userWalletModel
        self.coordinator = coordinator

        provider = userWalletModel.priceAlertsSubscriptionsProvider
        pushManager = userWalletModel.userWalletPushNotificationsManager

        setupToggleViewModel()
        bind()
    }

    deinit {
        // Fire-and-forget `runTask(in: self)` tasks weak-capture self and bail on dealloc;
        // this stored one owns an in-flight CoinsList request worth cancelling promptly.
        coinMetadataLoadTask?.cancel()
    }

    // MARK: - Lifecycle

    func onAppear() {
        // `isAuthorizedPublisher` only emits on `didBecomeActive`; prime the initial permission state.
        toggleInteractor.refreshSystemPermissionState()

        runTask(in: self) { viewModel in
            try? await viewModel.provider.fetch()
        }
    }

    func deleteTapped(tokenId: PriceAlertTokenId) {
        // Unsubscribe removes the coin from every wallet on the device — equivalent to turning off
        // the bell on the coin screen. The provider optimistically updates its set and rolls back on
        // failure, so the list refreshes reactively through `subscriptionsPublisher`.
        let deviceWalletIds = userWalletRepository.models.map(\.userWalletId.stringValue)

        runTask(in: self) { viewModel in
            do {
                try await viewModel.provider.unsubscribe(tokenId: tokenId, walletIds: deviceWalletIds)
            } catch {
                await viewModel.presentErrorAlert()
            }
        }
    }
}

// MARK: - Types

extension PriceAlertsScreenViewModel {
    enum WatchlistState {
        case loading
        case items([PriceAlertsWatchlistItemViewModel])
        case empty
        case error
    }
}

// MARK: - Master toggle

private extension PriceAlertsScreenViewModel {
    var showNotificationsBinding: BindingValue<Bool> {
        BindingValue<Bool>(
            root: self,
            default: false,
            get: { $0.showNotificationsEnabled },
            set: { viewModel, value in
                viewModel.showNotificationsEnabled = value
                viewModel.handleShowNotificationsToggle(value)
            }
        )
    }

    func setupToggleViewModel() {
        showNotificationsRowViewModel = DefaultToggleRowViewModel(
            // [REDACTED_TODO_COMMENT]
            title: "Show notifications",
            isOn: showNotificationsBinding
        )
    }

    /// Backend failures roll back automatically through `preferencesPublisher`; permission handling
    /// (pending enable, system prompt, settings alert) lives in the interactor.
    func handleShowNotificationsToggle(_ value: Bool) {
        toggleInteractor.toggle(value, for: .priceAlerts)
    }
}

// MARK: - Binding

private extension PriceAlertsScreenViewModel {
    func bind() {
        pushManager.preferencesPublisher
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, preferences in
                viewModel.applyPreferences(preferences)
            }
            .store(in: &bag)

        provider.subscriptionsPublisher
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, subscriptions in
                viewModel.applySubscriptions(subscriptions)
            }
            .store(in: &bag)

        quotesRepository.quotesPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, quotes in
                viewModel.quotes = quotes
                viewModel.rebuildWatchlist()
            }
            .store(in: &bag)
    }

    func applyPreferences(_ preferences: RemotePushPreferences) {
        guard case .ready = preferences.state else {
            return
        }

        showNotificationsEnabled = preferences.preference(for: .priceAlerts).isEnabled
    }

    func applySubscriptions(_ subscriptions: RemotePriceAlertsSubscriptions) {
        switch subscriptions.state {
        case .loading:
            watchlistState = .loading
        case .failed:
            watchlistState = .error
        case .ready(let tokenIds):
            subscribedTokenIds = Array(tokenIds)

            guard !tokenIds.isEmpty else {
                coinMetadataLoadTask?.cancel()
                coinMetadataLoadTask = nil
                isLoadingCoinMetadata = false
                coinMetadataById.removeAll()
                watchlistState = .empty
                return
            }

            loadCoinMetadataAndQuotes(for: Array(tokenIds))
        }
    }
}

// MARK: - Watchlist content loading

private extension PriceAlertsScreenViewModel {
    func loadCoinMetadataAndQuotes(for tokenIds: [PriceAlertTokenId]) {
        let missingMetadataIds = tokenIds.filter { coinMetadataById[$0] == nil }
        let missingQuoteIds = tokenIds.filter { quotes[$0] == nil }

        guard !missingMetadataIds.isEmpty else {
            isLoadingCoinMetadata = false
            rebuildWatchlist()
            loadQuotes(for: missingQuoteIds)
            return
        }

        // Hold the skeletons until names arrive — building rows now would flash raw token ids
        // ("bitcoin") as titles until CoinsList responds.
        isLoadingCoinMetadata = true
        watchlistState = .loading

        coinMetadataLoadTask?.cancel()
        coinMetadataLoadTask = runTask(in: self) { viewModel in
            // A failed load or a coin absent from the response (delisted, OQ-5) still ends in
            // visible rows: the id fallback with a "—" price keeps Delete available.
            let coins = (try? await viewModel.loadCoinMetadata(ids: missingMetadataIds)) ?? []

            guard !Task.isCancelled else {
                return
            }

            await viewModel.mergeMetadata(coins)
            viewModel.loadQuotes(for: missingQuoteIds)
        }
    }

    /// Requests only uncached quotes; results arrive through `quotesPublisher` and rebuild the rows.
    func loadQuotes(for tokenIds: [PriceAlertTokenId]) {
        guard !tokenIds.isEmpty else {
            return
        }

        runTask(in: self) { viewModel in
            _ = await viewModel.quotesRepository.loadQuotes(currencyIds: tokenIds)
        }
    }

    func loadCoinMetadata(ids: [PriceAlertTokenId]) async throws -> [CoinsList.Coin] {
        let request = CoinsList.Request(supportedBlockchains: [], ids: ids)
        let response = try await tangemApiService.loadCoins(requestModel: request)
        return response.coins
    }

    @MainActor
    func mergeMetadata(_ coins: [CoinsList.Coin]) {
        for coin in coins {
            coinMetadataById[coin.id] = coin
        }

        isLoadingCoinMetadata = false
        rebuildWatchlist()
    }

    func rebuildWatchlist() {
        // A quotes tick must not resurface rows while coin names are still loading (skeletons are shown).
        guard !subscribedTokenIds.isEmpty, !isLoadingCoinMetadata else {
            return
        }

        let items = subscribedTokenIds
            .map(makeItem(tokenId:))
            .sorted { $0.name.caseInsensitiveCompare($1.name) == .orderedAscending }

        watchlistState = .items(items)
    }

    func makeItem(tokenId: PriceAlertTokenId) -> PriceAlertsWatchlistItemViewModel {
        let coin = coinMetadataById[tokenId]
        let quote = quotes[tokenId]

        let priceText = quote.map { priceFormatter.formatPrice($0.price) } ?? Constants.missingValuePlaceholder
        let priceChangeState = priceChangeUtility.convertToPriceChangeState(changePercent: quote?.priceChange24h)

        return PriceAlertsWatchlistItemViewModel(
            id: tokenId,
            name: coin?.name ?? tokenId,
            symbol: coin?.symbol.uppercased() ?? "",
            iconURL: iconURLBuilder.tokenIconURL(id: tokenId),
            priceText: priceText,
            priceChangeState: priceChangeState
        )
    }
}

// MARK: - Alerts

private extension PriceAlertsScreenViewModel {
    @MainActor
    func presentErrorAlert() {
        alert = AlertBinder(
            title: Localization.commonError,
            message: Localization.commonSomethingWentWrong
        )
    }
}

// MARK: - PushChannelToggleInteractorOutput

extension PriceAlertsScreenViewModel: PushChannelToggleInteractorOutput {
    func revertToggle(for channel: PushChannel) {
        showNotificationsEnabled = false
    }

    /// Offers to open the app's system Settings when push permission is denied (Settings / Cancel).
    /// Mirrors the push-settings screen: Cancel drops the pending enable and reverts the toggle,
    /// while opening Settings keeps it pending so returning with permission auto-enables the channel.
    func presentEnablePushSettingsAlert(for channel: PushChannel) {
        alert = AlertBuilder.makeEnablePushSettingsAlert(
            onCancel: { [weak self] in
                self?.toggleInteractor.cancelPendingEnable(for: channel)
                self?.showNotificationsEnabled = false
            },
            onOpenSettings: { [weak self] in
                self?.coordinator?.openAppSettings()
            }
        )
    }

    func handlePreferenceUpdateFailure(for channel: PushChannel) {
        presentErrorAlert()
    }
}

// MARK: - Constants

private extension PriceAlertsScreenViewModel {
    enum Constants {
        static let missingValuePlaceholder = "—"
    }
}
