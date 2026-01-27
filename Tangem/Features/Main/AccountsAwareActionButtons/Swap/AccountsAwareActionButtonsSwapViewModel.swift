//
//  AccountsAwareActionButtonsSwapViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemLocalization
import TangemFoundation
import struct TangemUIUtils.AlertBinder

final class AccountsAwareActionButtonsSwapViewModel: ObservableObject {
    // MARK: - Published

    @Published private(set) var source: TokenItemType = .placeholder(text: Localization.actionButtonsYouWantToSwap)
    @Published private(set) var destination: TokenItemType?

    let tokenSelectorViewModel: AccountsAwareTokenSelectorViewModel

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
        coordinator: ActionButtonsSwapRoutable
    ) {
        self.tokenSelectorViewModel = tokenSelectorViewModel
        self.coordinator = coordinator

        // Here only possible direction is `from`
        tokenSelectorViewModel.setup(directionPublisher: filterTokenItem.map { $0.map { .fromSource($0) } })
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
            selectSourceToken(item: item)
        case .token(let source, _):
            Task {
                selectDestinationToken(item: item)
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
}

// MARK: - Private

private extension AccountsAwareActionButtonsSwapViewModel {
    func selectSourceToken(item: AccountsAwareTokenSelectorItem) {
        ActionButtonsAnalyticsService.trackTokenClicked(
            .swap,
            tokenSymbol: item.walletModel.tokenItem.currencySymbol
        )

        let viewModel = itemViewModelBuilder.mapToAccountsAwareTokenSelectorItemViewModel(item: item) {}

        source = .token(item, viewModel: viewModel)
        destination = .placeholder(text: Localization.actionButtonsYouWantToReceive)

        coordinator?.showYieldNotificationIfNeeded(for: item.walletModel, completion: nil)

        // All tokens are available for swap - actual pair check happens on the exchange screen
        // Just filter out the selected source token from destination list
        filterTokenItem.send(item.walletModel.tokenItem)
    }

    func selectDestinationToken(item: AccountsAwareTokenSelectorItem) {
        let viewModel = itemViewModelBuilder.mapToAccountsAwareTokenSelectorItemViewModel(item: item) {}
        destination = .token(item, viewModel: viewModel)
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
}
