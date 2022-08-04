//
//  OnboardingTopupViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import BlockchainSdk

class OnboardingTopupViewModel<Step: OnboardingStep>: OnboardingViewModel<Step> {
    @Injected(\.exchangeService) var exchangeService: ExchangeService

    @Published var refreshButtonState: OnboardingCircleButton.State = .refreshButton
    @Published var cardBalance: String = ""
    @Published var isBalanceRefresherVisible: Bool = false

    var walletModelUpdateCancellable: AnyCancellable?

    var cardModel: CardViewModel?

    var buyCryptoURL: URL? {
        if let wallet = cardModel?.wallets?.first {
            return exchangeService.getBuyUrl(currencySymbol: wallet.blockchain.currencySymbol,
                                             amountType: .coin,
                                             blockchain: wallet.blockchain,
                                             walletAddress: wallet.address)
        }

        return nil
    }

    var buyCryptoCloseUrl: String { exchangeService.successCloseUrl.removeLatestSlash() }

    private var shareAddress: String {
        cardModel?.walletModels?.first?.shareAddressString(for: 0) ?? ""
    }

    private var walletAddress: String {
        cardModel?.walletModels?.first?.displayAddress(for: 0) ?? ""
    }

    private var qrNoticeMessage: String {
        cardModel?.walletModels?.first?.getQRReceiveMessage() ?? ""
    }

    private var refreshButtonDispatchWork: DispatchWorkItem?
    private unowned var coordinator: OnboardingTopupRoutable!

    required init(input: OnboardingInput, coordinator: OnboardingTopupRoutable) {
        self.cardModel = input.cardInput.cardModel
        self.coordinator = coordinator
        super.init(input: input, onboardingCoordinator: coordinator)

        if let walletModel = self.cardModel?.walletModels?.first {
            updateCardBalanceText(for: walletModel)
        }
    }

    func updateCardBalance() {
        guard
            let walletModel = cardModel?.walletModels?.first,
            walletModelUpdateCancellable == nil
        else { return }

        refreshButtonState = .activityIndicator
        walletModelUpdateCancellable = walletModel.$state
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .sink { [weak self] walletModelState in
                guard let self = self else { return }

                self.updateCardBalanceText(for: walletModel)
                switch walletModelState {
                case .noAccount(let message):
                    print(message)
                    fallthrough
                case .idle:
                    if !walletModel.isEmptyIncludingPendingIncomingTxs {
                        self.goToNextStep()
                        self.walletModelUpdateCancellable = nil
                        return
                    }
                    self.resetRefreshButtonState()
                case .failed(let error):
                    self.alert = error.alertBinder
                    self.resetRefreshButtonState()
                case .loading, .created:
                    return
                }
                self.walletModelUpdateCancellable = nil
            }
        walletModel.update(silent: false)
    }

    func updateCardBalanceText(for model: WalletModel) {
        if case .failed = model.state {
            cardBalance = "–"
            return
        }

        if model.wallet.amounts.isEmpty {
            cardBalance = Amount(with: model.wallet.blockchain, type: .coin, value: 0).string(with: 8)
        } else {
            cardBalance = model.getBalance(for: .coin)
        }
    }

    private func resetRefreshButtonState() {
//        guard refreshButtonDispatchWork == nil else { return }
//
//        refreshButtonDispatchWork = DispatchWorkItem(block: {
        withAnimation {
            self.refreshButtonState = .refreshButton
        }
//            self.refreshButtonDispatchWork = nil
//        })
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: refreshButtonDispatchWork!)
    }

}

// MARK: - Navigation
extension OnboardingTopupViewModel {
    func openCryptoShop() {
        guard let url = buyCryptoURL else { return }

        coordinator.openCryptoShop(at: url, closeUrl: buyCryptoCloseUrl) { [weak self] _ in
            self?.updateCardBalance()
        }
    }

    func openQR() {
        coordinator.openQR(shareAddress: shareAddress, address: walletAddress, qrNotice: qrNoticeMessage)
    }
}
