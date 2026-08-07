//
//  ActionButtonsSellViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import struct TangemUIUtils.AlertBinder

final class ActionButtonsSellViewModel: ObservableObject {
    // MARK: - Dependencies

    @Injected(\.sellService)
    private var sellService: SellService

    // MARK: - ViewState

    @Published private(set) var notificationInput: NotificationViewInput?

    let tokenSelectorViewModel: TokenSelectorViewModel

    // MARK: - Private

    private weak var coordinator: ActionButtonsSellRoutable?
    private var bag: Set<AnyCancellable> = []

    init(
        tokenSelectorViewModel: TokenSelectorViewModel,
        coordinator: some ActionButtonsSellRoutable
    ) {
        self.tokenSelectorViewModel = tokenSelectorViewModel
        self.coordinator = coordinator

        tokenSelectorViewModel.setup(with: self)
        bind()
    }

    func onAppear() {
        ActionButtonsAnalyticsService.trackScreenOpened(.sell)
    }

    func close() {
        ActionButtonsAnalyticsService.trackCloseButtonTap(source: .sell)
        coordinator?.dismiss()
    }
}

// MARK: - TokenSelectorViewModelOutput

extension ActionButtonsSellViewModel: TokenSelectorViewModelOutput {
    func userDidSelect(item: TokenSelectorItem) {
        guard let walletModel = item.kind.walletModel else {
            return
        }

        ActionButtonsAnalyticsService.trackTokenClicked(.sell, tokenSymbol: walletModel.tokenItem.currencySymbol)

        coordinator?.openTransfer(walletModel: walletModel, userWalletInfo: item.userWalletInfo)
    }
}

// MARK: - Private

private extension ActionButtonsSellViewModel {
    func bind() {
        sellService
            .initializationPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, state in
                switch state {
                case .failed(.countryNotSupported):
                    viewModel.show(notification: .sellRegionalRestriction)
                default:
                    viewModel.show(notification: .none)
                }
            }
            .store(in: &bag)
    }

    func show(notification event: ActionButtonsNotificationEvent?) {
        guard let event else {
            notificationInput = .none
            return
        }

        let input = NotificationsFactory().buildNotificationInput(for: event)
        notificationInput = input
    }
}
