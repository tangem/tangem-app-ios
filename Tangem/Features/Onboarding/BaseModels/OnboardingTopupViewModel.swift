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

class OnboardingTopupViewModel<Step: OnboardingStep, Coordinator: OnboardingTopupRoutable>: OnboardingViewModel<Step, Coordinator> {
    @Injected(\.sellService) var sellService: SellService
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    @Published var refreshButtonState: OnboardingCircleButton.State = .refreshButton
    @Published var cardBalance: String = ""
    @Published var isBalanceRefresherVisible: Bool = false

    var walletModelUpdateCancellable: AnyCancellable?

    private var walletModel: (any WalletModel)? {
        userWalletModel?.walletModelsManager.walletModels.first
    }

    private var shareAddress: String {
        walletModel?.shareAddressString(for: 0) ?? ""
    }

    private var walletAddress: String {
        walletModel?.displayAddress(for: 0) ?? ""
    }

    private var qrNoticeMessage: String {
        walletModel?.qrReceiveMessage ?? ""
    }

    func updateCardBalance(shouldGoToNextStep: Bool = true) {
        guard
            let walletModel = userWalletModel?.walletModelsManager.walletModels.first,
            walletModelUpdateCancellable == nil
        else { return }

        refreshButtonState = .activityIndicator
        walletModelUpdateCancellable = walletModel.update(silent: false)
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, walletModelState in
                viewModel.updateCardBalanceText(for: walletModel)
                switch walletModelState {
                case .noAccount(let message, _):
                    AppLogger.info(viewModel, message)
                    fallthrough
                case .loaded:
                    if shouldGoToNextStep,
                       !walletModel.isEmptyIncludingPendingIncomingTxs,
                       walletModel.balanceState == .positive {
                        if let userWalletId = viewModel.userWalletModel?.userWalletId {
                            let balance = walletModel.fiatAvailableBalanceProvider.balanceType.value
                            Analytics.logTopUpIfNeeded(balance: balance ?? 0, for: userWalletId)
                        }
                        viewModel.goToNextStep()
                        viewModel.walletModelUpdateCancellable = nil
                        return
                    }

                    viewModel.resetRefreshButtonState()
                case .failed(let error):
                    viewModel.resetRefreshButtonState()

                    // Need check is display alert yet, because not to present an error if it is already shown
                    guard viewModel.alert == nil else {
                        return
                    }

                    viewModel.alert = error.alertBinder
                case .loading, .created:
                    return
                }
                viewModel.walletModelUpdateCancellable = nil
            }
    }

    func updateCardBalanceText(for model: any WalletModel) {
        if case .failed = model.state {
            cardBalance = AppConstants.enDashSign
            return
        }

        if model.isEmpty {
            let zeroAmount = Amount(with: model.tokenItem.blockchain, type: .coin, value: 0)
            cardBalance = zeroAmount.string(with: 8)
        } else {
            cardBalance = model.availableBalanceProvider.formattedBalanceType.value
        }
    }

    func resetRefreshButtonState() {
        withAnimation {
            self.refreshButtonState = .refreshButton
        }
    }
}

// MARK: - Navigation

extension OnboardingTopupViewModel {
    func openQR() {
        Analytics.log(.onboardingButtonShowTheWalletAddress)

        coordinator?.openQR(shareAddress: shareAddress, address: walletAddress, qrNotice: qrNoticeMessage)
    }

    func openBuyCrypto() {
        guard let walletModel, let userWalletModel else { return }

        Analytics.log(.buttonBuyCrypto)
        coordinator?.openOnramp(walletModel: walletModel, userWalletModel: userWalletModel)
    }
}

extension OnboardingTopupViewModel: CustomStringConvertible {
    public var description: String {
        return "OnboardingTopupViewModel"
    }
}
