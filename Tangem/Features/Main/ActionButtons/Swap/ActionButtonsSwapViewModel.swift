//
//  ActionButtonsSwapViewModel.swift
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

final class ActionButtonsSwapViewModel: ObservableObject {
    // MARK: - Injected

    @Injected(\.expressPairsRepository)
    private var expressPairsRepository: ExpressPairsRepository

    // MARK: - Published

    @Published private(set) var source: TokenItemType = .placeholder(text: Localization.actionButtonsYouWantToSwap)
    @Published private(set) var notificationInput: NotificationViewInput?
    @Published private(set) var notificationIsLoading: Bool = false
    @Published private(set) var destination: TokenItemType?

    let tokenSelectorViewModel: TokenSelectorViewModel
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
    /// Hence, `AvailableTokenSelectorItemAvailabilityProvider` is used here.
    private let itemViewModelBuilder = TokenSelectorItemViewModelBuilder(
        availabilityProvider: AvailableTokenSelectorItemAvailabilityProvider()
    )

    private weak var coordinator: ActionButtonsSwapRoutable?

    private var marketsTokenAdditionCoordinator: SwapMarketsTokenAdditionRoutable?
    private var destinationSelectionTask: Task<Void, Never>?

    init(
        tokenSelectorViewModel: TokenSelectorViewModel,
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

// MARK: - TokenSelectorViewModelOutput

extension ActionButtonsSwapViewModel: TokenSelectorViewModelOutput {
    func userDidSelect(item: TokenSelectorItem) {
        switch source {
        case .placeholder:
            Task { await updateSourceToken(item: item) }
        case .token(let sourceItem, _):
            logPortfolioTokenSelected(item: item)
            destinationSelectionTask?.cancel()
            destinationSelectionTask = Task { [weak self] in
                await MainActor.run { [weak self] in
                    self?.tokenSelectorViewModel.triggerScrollToTop()
                    self?.updateDestinationToken(item: item)
                }

                do {
                    try await Task.sleep(for: .seconds(Constants.scrollAnimationDelay))
                } catch {
                    return
                }

                await MainActor.run { [weak self] in
                    self?.openSwap(source: sourceItem, receive: item)
                }
            }
        }
    }
}

extension ActionButtonsSwapViewModel: SwapMarketsTokenSelectionHandler {
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

extension ActionButtonsSwapViewModel {
    func selectNewToken(_ item: TokenSelectorItem) {
        guard case .token(let sourceItem, _) = source else {
            return
        }

        openSwap(source: sourceItem, receive: item)
    }

    private func openSwap(
        source: TokenSelectorItem,
        receive: TokenSelectorItem,
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

private extension ActionButtonsSwapViewModel {
    func updateSourceToken(item: TokenSelectorItem) async {
        ActionButtonsAnalyticsService.trackTokenClicked(
            .swap,
            tokenSymbol: item.tokenItem.currencySymbol
        )

        let viewModel = itemViewModelBuilder.mapToTokenSelectorItemViewModel(item: item) {}

        await MainActor.run {
            source = .token(item, viewModel: viewModel)
            destination = .placeholder(text: Localization.actionButtonsYouWantToReceive)
            tokenSelectorViewModel.triggerScrollToTop()
        }

        try? await Task.sleep(for: .seconds(Constants.scrollAnimationDelay))

        await updatePairs(sourceItem: item)
    }

    func updateDestinationToken(item: TokenSelectorItem) {
        let viewModel = itemViewModelBuilder.mapToTokenSelectorItemViewModel(item: item) {}
        destination = .token(item, viewModel: viewModel)
    }

    func updatePairs(sourceItem: TokenSelectorItem) async {
        await MainActor.run { notificationIsLoading = true }

        do {
            _ = try await runWithDelayedLoading {
                self.tokenSelectorViewModel.setLoading()
            } operation: {
                try await self.expressPairsRepository.updatePairs(
                    for: sourceItem.tokenItem.expressCurrency,
                    userWalletInfo: sourceItem.userWalletInfo
                )
            }.value

            // We set the `filterTokenItem` after pairs is loading
            try await Task.sleep(for: .seconds(Constants.scrollAnimationDelay))
            filterTokenItem.send(sourceItem.tokenItem)
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

    func logPortfolioTokenSelected(item: TokenSelectorItem) {
        let analyticsLogger = SwapSelectTokenAnalyticsLogger(
            source: .portfolio,
            userHasSearchedDuringThisSession: false
        )
        analyticsLogger.logTokenSelected(coinSymbol: item.tokenItem.currencySymbol)
    }
}

extension ActionButtonsSwapViewModel {
    enum TokenItemType: Identifiable {
        case placeholder(text: String)
        case token(TokenSelectorItem, viewModel: TokenSelectorItemViewModel)

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

    enum Constants {
        static let floatingSheetDismissDelay: TimeInterval = 0.2
        static let scrollAnimationDelay: TimeInterval = 0.3
    }
}
