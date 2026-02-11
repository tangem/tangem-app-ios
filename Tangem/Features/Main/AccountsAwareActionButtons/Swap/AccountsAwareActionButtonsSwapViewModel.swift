//
//  AccountsAwareActionButtonsSwapViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemExpress
import TangemLocalization
import TangemFoundation
import struct TangemUIUtils.AlertBinder

final class AccountsAwareActionButtonsSwapViewModel: ObservableObject {
    // MARK: - Injected

    @Injected(\.expressPairsRepository)
    private var expressPairsRepository: ExpressPairsRepository

    // MARK: - Published

    @Published private(set) var source: TokenItemType = .placeholder(text: Localization.actionButtonsYouWantToSwap)
    @Published private(set) var notificationInput: NotificationViewInput?
    @Published private(set) var notificationIsLoading: Bool = false
    @Published private(set) var destination: TokenItemType?
    @Published private(set) var tokenSelectorState: TokenSelectorState = .selector

    let tokenSelectorViewModel: AccountsAwareTokenSelectorViewModel
    let marketsTokensViewModel: SwapMarketsTokensViewModel?

    var sourceHeaderType: ExpressCurrencyHeaderType {
        makeHeaderType(for: source, viewType: .send)
    }

    var destinationHeaderType: ExpressCurrencyHeaderType {
        makeHeaderType(for: destination, viewType: .receive)
    }

    // MARK: - Private

    private let filterTokenItem: CurrentValueSubject<TokenItem?, Never> = .init(nil)

    /// Selected source/destination token should be always available, otherwise it couldn't be selected.
    /// Hence, `AvailableAccountsAwareTokenSelectorItemAvailabilityProvider` is used here.
    private let itemViewModelBuilder = AccountsAwareTokenSelectorItemViewModelBuilder(
        availabilityProvider: AvailableAccountsAwareTokenSelectorItemAvailabilityProvider()
    )

    private weak var coordinator: ActionButtonsSwapRoutable?

    init(
        tokenSelectorViewModel: AccountsAwareTokenSelectorViewModel,
        marketsTokensViewModel: SwapMarketsTokensViewModel?,
        coordinator: ActionButtonsSwapRoutable,
    ) {
        self.tokenSelectorViewModel = tokenSelectorViewModel
        self.marketsTokensViewModel = marketsTokensViewModel
        self.coordinator = coordinator

        // Here only possible direction is `from`
        tokenSelectorViewModel.setup(directionPublisher: filterTokenItem.map { $0.map { .fromSource($0) } })
        tokenSelectorViewModel.setup(with: self)

        // Setup isActive publisher: markets are only active when source is selected (destination mode)
        let isActivePublisher = $source
            .map { source -> Bool in
                switch source {
                case .placeholder: return false
                case .token: return true
                }
            }
            .eraseToAnyPublisher()

//        marketsTokensViewModel?.setup(isActivePublisher: isActivePublisher)
        marketsTokensViewModel?.setup(searchTextPublisher: tokenSelectorViewModel.$searchText)
        marketsTokensViewModel?.setup(selectionHandler: self)
    }

    var shouldShowMarketsSearch: Bool {
        switch source {
        case .placeholder: return false
        case .token: return true
        }
    }

    func onAppear() {
        ActionButtonsAnalyticsService.trackScreenOpened(.swap)
    }

    func close() {
        coordinator?.dismiss()
    }

    func removeSourceTokenAction() -> (() -> Void)? {
        switch source {
        case .placeholder:
            return nil
        case .token:
            return { [weak self] in
                self?.show(notification: .none)
                self?.filterTokenItem.send(.none)

                self?.source = .placeholder(text: Localization.actionButtonsYouWantToSwap)
                self?.destination = .none
            }
        }
    }
}

// MARK: - AccountsAwareTokenSelectorViewModelOutput

extension AccountsAwareActionButtonsSwapViewModel: AccountsAwareTokenSelectorViewModelOutput {
    func usedDidSelect(item: AccountsAwareTokenSelectorItem) {
        switch source {
        case .placeholder:
            Task { await updateSourceToken(item: item) }
        case .token(let source, _):
            Task {
                await updateDestinationToken(item: item)
                try? await Task.sleep(for: .seconds(0.2))

                await MainActor.run {
                    coordinator?.openExpress(
                        input: .init(
                            userWalletInfo: item.userWalletInfo,
                            source: ExpressInteractorWalletModelWrapper(
                                userWalletInfo: source.userWalletInfo,
                                walletModel: source.walletModel,
                                expressOperationType: .swap
                            ),
                            destination: .chosen(
                                ExpressInteractorWalletModelWrapper(
                                    userWalletInfo: item.userWalletInfo,
                                    walletModel: item.walletModel,
                                    expressOperationType: .swap
                                )
                            )
                        )
                    )
                }
            }
        }
    }

    func userDidSelectNewlyAddedToken(item: AccountsAwareTokenSelectorItem) {
        switch source {
        case .placeholder:
            Task { await updateSourceToken(item: item, isNewlyAddedFromMarkets: true) }
        case .token(let source, _):
            Task {
                await updateDestinationToken(item: item)
                try? await Task.sleep(for: .seconds(0.2))

                await MainActor.run {
                    coordinator?.openExpress(
                        input: .init(
                            userWalletInfo: item.userWalletInfo,
                            source: ExpressInteractorWalletModelWrapper(
                                userWalletInfo: source.userWalletInfo,
                                walletModel: source.walletModel,
                                expressOperationType: .swap
                            ),
                            destination: .chosen(
                                ExpressInteractorWalletModelWrapper(
                                    userWalletInfo: item.userWalletInfo,
                                    walletModel: item.walletModel,
                                    expressOperationType: .swap,
                                    isNewlyAddedFromMarkets: true
                                )
                            )
                        )
                    )
                }
            }
        }
    }
}

extension AccountsAwareActionButtonsSwapViewModel: SwapMarketsTokenSelectionHandler {
    func didSelectExternalToken(_ token: MarketsTokenModel) {
        Task { @MainActor in
            guard let networks = token.networks, !networks.isEmpty else {
                AppLogger.debug("Selected tokens with no networks")
                return
            }

            let inputData = ExpressAddTokenInputData(
                coinId: token.id,
                coinName: token.name,
                coinSymbol: token.symbol,
                networks: networks
            )

            coordinator?.openAddTokenFlowForExpress(inputData: inputData)
        }
    }
}

// MARK: - Private

private extension AccountsAwareActionButtonsSwapViewModel {
    func checkNoDestinationTokens(tokenItem: TokenItem, isNewlyAddedFromMarkets: Bool = false) async {
        guard await expressPairsRepository.getPairs(from: tokenItem.expressCurrency).isEmpty else {
            await MainActor.run { show(notification: .none) }
            return
        }

        await MainActor.run {
            if isNewlyAddedFromMarkets {
                show(notification: .swapNotSupportedForToken(tokenName: tokenItem.name))
            } else {
                show(notification: .noAvailablePairs)
            }
        }
    }

    func updateSourceToken(item: AccountsAwareTokenSelectorItem, isNewlyAddedFromMarkets: Bool = false) async {
        ActionButtonsAnalyticsService.trackTokenClicked(
            .swap,
            tokenSymbol: item.walletModel.tokenItem.currencySymbol
        )

        let viewModel = itemViewModelBuilder.mapToAccountsAwareTokenSelectorItemViewModel(item: item) {}

        await MainActor.run {
            source = .token(item, viewModel: viewModel)
            destination = .placeholder(text: Localization.actionButtonsYouWantToReceive)

            coordinator?.showYieldNotificationIfNeeded(for: item.walletModel, completion: nil)
        }

        await updatePairs(sourceItem: item, isNewlyAddedFromMarkets: isNewlyAddedFromMarkets)
    }

    func updateDestinationToken(item: AccountsAwareTokenSelectorItem) async {
        let viewModel = itemViewModelBuilder.mapToAccountsAwareTokenSelectorItemViewModel(item: item) {}
        await MainActor.run {
            destination = .token(item, viewModel: viewModel)
        }
    }

    func updatePairs(sourceItem: AccountsAwareTokenSelectorItem, isNewlyAddedFromMarkets: Bool = false) async {
        await MainActor.run { notificationIsLoading = true }

        do {
            _ = try await runWithDelayedLoading {
                self.tokenSelectorState = .loading
            } operation: {
                try await self.expressPairsRepository.updatePairs(
                    for: sourceItem.walletModel.tokenItem.expressCurrency,
                    userWalletInfo: sourceItem.userWalletInfo
                )
            }.value

            // We set the `filterTokenItem` after pairs is loading
            filterTokenItem.send(sourceItem.walletModel.tokenItem)
            await checkNoDestinationTokens(tokenItem: sourceItem.walletModel.tokenItem, isNewlyAddedFromMarkets: isNewlyAddedFromMarkets)

            await MainActor.run {
                tokenSelectorState = .selector
            }
        } catch let error as ExpressAPIError {
            await MainActor.run {
                if isNewlyAddedFromMarkets {
                    show(notification: .swapNotSupportedForToken(tokenName: sourceItem.walletModel.tokenItem.name))
                } else {
                    show(notification: .refreshRequired(
                        title: error.localizedTitle,
                        message: error.localizedMessage
                    ))
                }
            }
        } catch {
            await MainActor.run {
                if isNewlyAddedFromMarkets {
                    show(notification: .swapNotSupportedForToken(tokenName: sourceItem.walletModel.tokenItem.name))
                } else {
                    show(notification: .refreshRequired(
                        title: Localization.commonError,
                        message: Localization.commonUnknownError
                    ))
                }
            }
        }

        await MainActor.run { notificationIsLoading = false }
    }

    func show(notification event: ActionButtonsNotificationEvent?) {
        guard let event else {
            notificationInput = .none
            return
        }

        let input = NotificationsFactory().buildNotificationInput(for: event, buttonAction: { [weak self] id, type in
            Task {
                if case .token(let item, _) = self?.source {
                    await self?.updatePairs(sourceItem: item)
                }
            }
        })

        notificationInput = input
    }

    func makeHeaderType(for tokenItemType: TokenItemType?, viewType: ExpressCurrencyViewType) -> ExpressCurrencyHeaderType {
        switch tokenItemType {
        case .none,
             .placeholder:
            return ExpressCurrencyHeaderType(viewType: viewType, tokenHeader: nil)
        case .token(let item, _):
            let provider = ExpressInteractorTokenHeaderProvider(
                userWalletInfo: item.userWalletInfo,
                account: item.account
            )
            let tokenHeader = provider.makeHeader()
            return ExpressCurrencyHeaderType(viewType: viewType, tokenHeader: tokenHeader)
        }
    }
}

extension AccountsAwareActionButtonsSwapViewModel {
    enum TokenItemType: Identifiable {
        case placeholder(text: String)
        case token(AccountsAwareTokenSelectorItem, viewModel: AccountsAwareTokenSelectorItemViewModel)

        var id: String {
            switch self {
            case .placeholder(let text): text
            case .token(let token, _): token.id
            }
        }

        var tokenItem: TokenItem? {
            switch self {
            case .placeholder: .none
            case .token(let item, _): item.walletModel.tokenItem
            }
        }
    }

    enum TokenSelectorState: Identifiable {
        case loading
        case selector

        var id: String {
            switch self {
            case .loading: "loading"
            case .selector: "selector"
            }
        }
    }
}
