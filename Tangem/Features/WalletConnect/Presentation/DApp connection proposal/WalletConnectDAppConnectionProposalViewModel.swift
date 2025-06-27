//
//  WalletConnectDAppConnectionProposalViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemUI

@MainActor
final class WalletConnectDAppConnectionProposalViewModel: ObservableObject {
    private let hapticFeedbackGenerator: any WalletConnectHapticFeedbackGenerator
    private let userWallets: [any UserWalletModel]
    private var selectedUserWallet: any UserWalletModel

    private let connectionRequestViewModel: WalletConnectDAppConnectionRequestViewModel
    private lazy var walletSelectorViewModel: WalletConnectWalletSelectorViewModel = makeWalletSelectorViewModel()
    private lazy var networksSelectorViewModel: WalletConnectNetworksSelectorViewModel = makeNetworksSelectorViewModel()

    private let dismissFlowAction: () -> Void

    private var connectionRequestViewModelCancellable: AnyCancellable?

    @Published private(set) var state: WalletConnectDAppConnectionProposalViewState

    init(
        getDAppConnectionProposalUseCase: WalletConnectGetDAppConnectionProposalUseCase,
        connectDAppUseCase: WalletConnectConnectDAppUseCase,
        hapticFeedbackGenerator: some WalletConnectHapticFeedbackGenerator,
        userWallets: [any UserWalletModel],
        selectedUserWallet: some UserWalletModel,
        dismissFlowAction: @escaping () -> Void
    ) {
        connectionRequestViewModel = WalletConnectDAppConnectionRequestViewModel(
            state: .loading(selectedUserWalletName: selectedUserWallet.name, walletSelectionIsAvailable: userWallets.count > 1),
            getDAppConnectionProposalUseCase: getDAppConnectionProposalUseCase,
            resolveAvailableBlockchainsUseCase: WalletConnectResolveAvailableBlockchainsUseCase(),
            connectDAppUseCase: connectDAppUseCase,
            hapticFeedbackGenerator: hapticFeedbackGenerator,
            selectedUserWallet: selectedUserWallet
        )
        state = .connectionRequest(connectionRequestViewModel)

        self.hapticFeedbackGenerator = hapticFeedbackGenerator
        self.userWallets = userWallets
        self.selectedUserWallet = selectedUserWallet

        self.dismissFlowAction = dismissFlowAction

        setupConnectionRequestViewModel()
    }

    func beginDAppProposalLoading() {
        connectionRequestViewModel.handle(viewEvent: .dAppProposalLoadingRequested)
    }

    func switchToConnectionRequest() {
        state = .connectionRequest(connectionRequestViewModel)
    }

    private func setupConnectionRequestViewModel() {
        connectionRequestViewModel.coordinator = self

        connectionRequestViewModelCancellable = connectionRequestViewModel
            .objectWillChange
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
    }
}

// MARK: - WalletConnectDAppConnectionProposalRoutable

extension WalletConnectDAppConnectionProposalViewModel: WalletConnectDAppConnectionProposalRoutable {
    func openConnectionRequest() {
        connectionRequestViewModel.updateSelectedUserWallet(selectedUserWallet)

        state = .connectionRequest(connectionRequestViewModel)
    }

    func openVerifiedDomain(for dAppName: String) {
        let viewModel = WalletConnectDAppDomainVerificationViewModel(
            verifiedDAppName: dAppName,
            closeAction: { [weak self] in
                self?.openConnectionRequest()
            }
        )

        state = .verifiedDomain(viewModel)
    }

    func openDomainVerificationWarning(
        _ verificationStatus: WalletConnectDAppVerificationStatus,
        cancelAction: @escaping () async -> Void,
        connectAnywayAction: @escaping () async -> Void
    ) {
        let viewModel = WalletConnectDAppDomainVerificationViewModel(
            warningVerificationStatus: verificationStatus,
            closeAction: { [weak self] in
                self?.dismiss()
            },
            cancelAction: cancelAction,
            connectAnywayAction: connectAnywayAction
        )

        state = .verifiedDomain(viewModel)
    }

    func openWalletSelector() {
        walletSelectorViewModel.updateSelectedUserWallet(selectedUserWallet)
        state = .walletSelector(walletSelectorViewModel)
    }

    func openNetworksSelector(_ blockchainsAvailabilityResult: WalletConnectDAppBlockchainsAvailabilityResult) {
        networksSelectorViewModel.update(with: blockchainsAvailabilityResult)
        state = .networkSelector(networksSelectorViewModel)
    }

    func openErrorScreen(error: some Error) {
        // [REDACTED_TODO_COMMENT]
    }

    func dismiss() {
        dismissFlowAction()
    }

    func showErrorToast(with message: String) {
        Toast(view: WarningToast(text: message))
            .present(layout: .top(padding: 20), type: .temporary())
    }

    func showSuccessToast(with message: String) {
        Toast(view: SuccessToast(text: message))
            .present(layout: .top(padding: 20), type: .temporary())
    }
}

// MARK: - Factory methods

extension WalletConnectDAppConnectionProposalViewModel {
    private func makeWalletSelectorViewModel() -> WalletConnectWalletSelectorViewModel {
        WalletConnectWalletSelectorViewModel(
            userWallets: userWallets,
            selectedUserWallet: selectedUserWallet,
            hapticFeedbackGenerator: hapticFeedbackGenerator,
            backAction: { [weak self] in
                self?.openConnectionRequest()
            },
            userWalletSelectedAction: { [weak self] selectedUserWallet in
                guard case .walletSelector = self?.state else { return }
                self?.selectedUserWallet = selectedUserWallet
                self?.openConnectionRequest()
            }
        )
    }

    private func makeNetworksSelectorViewModel() -> WalletConnectNetworksSelectorViewModel {
        WalletConnectNetworksSelectorViewModel(
            backAction: { [weak self] in
                self?.openConnectionRequest()
            },
            doneAction: { [weak self] selectedBlockchains in
                self?.connectionRequestViewModel.updateSelectedBlockchains(selectedBlockchains)
                self?.openConnectionRequest()
            }
        )
    }
}
