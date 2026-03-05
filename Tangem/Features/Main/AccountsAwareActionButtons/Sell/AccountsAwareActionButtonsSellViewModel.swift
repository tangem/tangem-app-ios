//
//  AccountsAwareActionButtonsSellViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import struct TangemUIUtils.AlertBinder

final class AccountsAwareActionButtonsSellViewModel: ObservableObject {
    // MARK: - Dependencies

    @Injected(\.sellService)
    private var sellService: SellService

    // MARK: - ViewState

    @Published private(set) var notificationInput: NotificationViewInput?

    let tokenSelectorViewModel: AccountsAwareTokenSelectorViewModel

    // MARK: - Private

    private weak var coordinator: ActionButtonsSellRoutable?
    private var bag: Set<AnyCancellable> = []

    init(
        tokenSelectorViewModel: AccountsAwareTokenSelectorViewModel,
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

// MARK: - AccountsAwareTokenSelectorViewModelOutput

extension AccountsAwareActionButtonsSellViewModel: AccountsAwareTokenSelectorViewModelOutput {
    func userDidSelect(item: AccountsAwareTokenSelectorItem) {
        ActionButtonsAnalyticsService.trackTokenClicked(.sell, tokenSymbol: item.walletModel.tokenItem.currencySymbol)

        guard let url = makeSellUrl(walletModel: item.walletModel) else {
            return
        }

        coordinator?.openSellCrypto(at: url) { [weak self] response in
            self?.makeSendToSellModel(from: response, and: item.walletModel)
        }
    }
}

// MARK: - Private

private extension AccountsAwareActionButtonsSellViewModel {
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

    func makeSendToSellModel(from response: String, and walletModel: any WalletModel) -> ActionButtonsSendToSellModel? {
        let sellUtility = SellCryptoUtility(
            tokenItem: walletModel.tokenItem,
            address: walletModel.defaultAddressString
        )

        guard let sellCryptoRequest = sellUtility.extractSellCryptoRequest(from: response) else {
            return nil
        }

        let sellParameters = PredefinedSellParameters(
            amount: sellCryptoRequest.amount,
            destination: sellCryptoRequest.targetAddress,
            tag: sellCryptoRequest.tag
        )

        return .init(sellParameters: sellParameters, walletModel: walletModel)
    }

    func makeSellUrl(walletModel: any WalletModel) -> URL? {
        let sellUrl = sellService.getSellUrl(
            currencySymbol: walletModel.tokenItem.currencySymbol,
            amountType: walletModel.tokenItem.amountType,
            blockchain: walletModel.tokenItem.blockchain,
            walletAddress: walletModel.defaultAddressString
        )

        return sellUrl
    }
}
