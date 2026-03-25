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
import TangemPay

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

    var sourceHeaderType: SendTokenHeader {
        makeHeaderType(for: source, isSource: true)
    }

    var destinationHeaderType: SendTokenHeader {
        makeHeaderType(for: destination, isSource: false)
    }

    // MARK: - Private

    private let filterTokenItem: CurrentValueSubject<TokenItem?, Never> = .init(nil)

    /// Selected source/destination token should be always available, otherwise it couldn't be selected.
    /// Hence, `AvailableAccountsAwareTokenSelectorItemAvailabilityProvider` is used here.
    private let itemViewModelBuilder = AccountsAwareTokenSelectorItemViewModelBuilder(
        availabilityProvider: AvailableAccountsAwareTokenSelectorItemAvailabilityProvider()
    )

    private weak var coordinator: ActionButtonsSwapRoutable?

    private var marketsTokenAdditionCoordinator: SwapMarketsTokenAdditionRoutable?

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
    func userDidSelect(item: AccountsAwareTokenSelectorItem) {
        switch source {
        case .placeholder:
            Task { await updateSourceToken(item: item) }
        case .token(let sourceItem, _):
            logPortfolioTokenSelected(item: item)
            openSwap(source: sourceItem, receive: item)
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
                networks: networks,
                userHasSearchedDuringThisSession: marketsTokensViewModel?.userHasSearchedDuringThisSession ?? false
            )

            marketsTokenAdditionCoordinator = SwapMarketsTokenAdditionCoordinator { [weak self] item in
                self?.selectNewToken(item)
                self?.marketsTokenAdditionCoordinator = nil
            }

            marketsTokenAdditionCoordinator?.requestAddToken(inputData: inputData)
        }
    }
}

// MARK: - Market Token Addition

extension AccountsAwareActionButtonsSwapViewModel {
    func selectNewToken(_ item: AccountsAwareTokenSelectorItem) {
        guard case .token(let sourceItem, _) = source else {
            return
        }

        openSwap(source: sourceItem, receive: item)
    }

    private func openSwap(
        source: AccountsAwareTokenSelectorItem,
        receive: AccountsAwareTokenSelectorItem,
    ) {
        let source = source
            .makeSendSwapableTokenFactory(expressOperationType: .swap)
            .makeSwapableToken()

        let receive = receive
            .makeSendSwapableTokenFactory(expressOperationType: .swap)
            .makeSwapableToken()

        let input = PredefinedSwapParameters.from(source, receive: receive)
        coordinator?.openSwap(input: input)
    }
}

// MARK: - Private

private extension AccountsAwareActionButtonsSwapViewModel {
    func updateSourceToken(item: AccountsAwareTokenSelectorItem) async {
        ActionButtonsAnalyticsService.trackTokenClicked(
            .swap,
            tokenSymbol: item.tokenItem.currencySymbol
        )

        let viewModel = itemViewModelBuilder.mapToAccountsAwareTokenSelectorItemViewModel(item: item) {}

        await MainActor.run {
            source = .token(item, viewModel: viewModel)
            destination = .placeholder(text: Localization.actionButtonsYouWantToReceive)

            if let walletModel = item.kind.walletModel {
                coordinator?.showYieldNotificationIfNeeded(for: walletModel, completion: nil)
            }
        }

        await updatePairs(sourceItem: item)
    }

    func updateDestinationToken(item: AccountsAwareTokenSelectorItem) async {
        let viewModel = itemViewModelBuilder.mapToAccountsAwareTokenSelectorItemViewModel(item: item) {}
        await MainActor.run {
            destination = .token(item, viewModel: viewModel)
        }
    }

    func updatePairs(sourceItem: AccountsAwareTokenSelectorItem) async {
        await MainActor.run { notificationIsLoading = true }

        do {
            _ = try await runWithDelayedLoading {
                self.tokenSelectorState = .loading
            } operation: {
                try await self.expressPairsRepository.updatePairs(
                    for: sourceItem.tokenItem.expressCurrency,
                    userWalletInfo: sourceItem.userWalletInfo
                )
            }.value

            // We set the `filterTokenItem` after pairs is loading
            filterTokenItem.send(sourceItem.tokenItem)

            await MainActor.run {
                tokenSelectorState = .selector
            }
        } catch let error as ExpressAPIError {
            await MainActor.run {
                show(notification: .refreshRequired(
                    title: error.localizedTitle,
                    message: error.localizedMessage
                ))
            }
        } catch {
            await MainActor.run {
                show(notification: .refreshRequired(
                    title: Localization.commonError,
                    message: Localization.commonUnknownError
                ))
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

    func makeHeaderType(for tokenItemType: TokenItemType?, isSource: Bool) -> SendTokenHeader {
        switch tokenItemType {
        case .none, .placeholder:
            return .action(name: isSource ? Localization.swappingFromTitle : Localization.swappingToTitle)
        case .token(let item, _):
            let tokenHeader = TokenHeaderProvider(
                userWalletName: item.userWalletInfo.name,
                account: item.kind.account
            ).makeHeader()

            return tokenHeader.asSendTokenHeader(actionType: .swap, isSource: isSource)
        }
    }

    func logPortfolioTokenSelected(item: AccountsAwareTokenSelectorItem) {
        let analyticsLogger = SwapSelectTokenAnalyticsLogger(
            source: .portfolio,
            userHasSearchedDuringThisSession: false
        )
        analyticsLogger.logTokenSelected(coinSymbol: item.tokenItem.currencySymbol)
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
            case .token(let item, _): item.tokenItem
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

extension AccountsAwareActionButtonsSwapViewModel {
    enum Constants {
        static let floatingSheetDismissDelay: TimeInterval = 0.2
    }
}
