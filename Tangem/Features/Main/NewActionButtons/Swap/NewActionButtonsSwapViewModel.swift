//
//  NewActionButtonsSwapViewModel.swift
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

final class NewActionButtonsSwapViewModel: ObservableObject {
    // MARK: - Injected

    @Injected(\.expressPairsRepository)
    private var expressPairsRepository: ExpressPairsRepository

    // MARK: - Published

    @Published private(set) var source: TokenItemType = .placeholder(text: Localization.actionButtonsYouWantToSwap)
    @Published private(set) var notificationInput: NotificationViewInput?
    @Published private(set) var notificationIsLoading: Bool = false
    @Published private(set) var destination: TokenItemType?
    @Published private(set) var tokenSelectorState: TokenSelectorState = .selector

    let tokenSelectorViewModel: NewTokenSelectorViewModel

    // MARK: - Private

    private let filterTokenItem: CurrentValueSubject<TokenItem?, Never> = .init(nil)

    private weak var coordinator: ActionButtonsSwapRoutable?

    init(coordinator: ActionButtonsSwapRoutable) {
        self.coordinator = coordinator

        tokenSelectorViewModel = NewTokenSelectorViewModel(
            walletsProvider: SwapNewTokenSelectorWalletsProvider(
                // `selectedItem` for remove it from list
                selectedItem: filterTokenItem.eraseToAnyPublisher(),

                // `directionPublisher` for filter with available pairs from `filterTokenItem`
                availabilityProviderFactory: NewTokenSelectorItemSwapAvailabilityProviderFactory(
                    // Here only possible pair `from`
                    directionPublisher: filterTokenItem.map { $0.map { .fromSource($0) } }.eraseToAnyPublisher()
                )
            )
        )
        tokenSelectorViewModel.setup(with: self)
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

// MARK: - NewTokenSelectorViewModelOutput

extension NewActionButtonsSwapViewModel: NewTokenSelectorViewModelOutput {
    func usedDidSelect(item: NewTokenSelectorItem) {
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
                                walletModel: source.walletModel
                            ),
                            destination: .chosen(
                                ExpressInteractorWalletModelWrapper(
                                    userWalletInfo: item.userWalletInfo,
                                    walletModel: item.walletModel
                                )
                            )
                        )
                    )
                }
            }
        }
    }
}

// MARK: - Private

private extension NewActionButtonsSwapViewModel {
    func checkNoDestinationTokens(tokenItem: TokenItem) async {
        guard await expressPairsRepository.getPairs(from: tokenItem.expressCurrency).isEmpty else {
            await MainActor.run { show(notification: .none) }
            return
        }

        await MainActor.run {
            show(notification: .noAvailablePairs)
        }
    }

    func updateSourceToken(item: NewTokenSelectorItem) async {
        ActionButtonsAnalyticsService.trackTokenClicked(
            .swap,
            tokenSymbol: item.walletModel.tokenItem.currencySymbol
        )

        let viewModel = tokenSelectorViewModel.mapToNewTokenSelectorItemViewModel(item: item)

        await MainActor.run {
            source = .token(item, viewModel: viewModel)
            destination = .placeholder(text: Localization.actionButtonsYouWantToReceive)

            coordinator?.showYieldNotificationIfNeeded(for: item.walletModel, completion: nil)
        }

        await updatePairs(sourceItem: item)
    }

    func updateDestinationToken(item: NewTokenSelectorItem) async {
        let viewModel = tokenSelectorViewModel.mapToNewTokenSelectorItemViewModel(item: item)
        await MainActor.run {
            destination = .token(item, viewModel: viewModel)
        }
    }

    func updatePairs(sourceItem: NewTokenSelectorItem) async {
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
            await checkNoDestinationTokens(tokenItem: sourceItem.walletModel.tokenItem)

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
}

extension NewActionButtonsSwapViewModel {
    enum TokenItemType: Identifiable {
        case placeholder(text: String)
        case token(NewTokenSelectorItem, viewModel: NewTokenSelectorItemViewModel)

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
