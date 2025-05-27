//
//  WalletConnectDAppConnectionProposalViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

@MainActor
final class WalletConnectDAppConnectionProposalViewModel: ObservableObject {
    private let userWallets: [any UserWalletModel]

    private let connectionRequestViewModel: WalletConnectDAppConnectionRequestViewModel

    private lazy var walletSelectorViewModel = WalletConnectWalletSelectorViewModel(
        userWallets: userWallets,
        selectedWallet: connectionRequestViewModel.selectedUserWallet,
        backAction: { [weak self] in
            self?.openConnectionRequest()
        },
        userWalletSelectedAction: { [connectionRequestViewModel] selectedUserWallet in
            connectionRequestViewModel.selectedUserWallet = selectedUserWallet
        }
    )

    private let dismissFlowAction: () -> Void

    private var connectionRequestViewModelCancellable: AnyCancellable?

    @Published private(set) var state: WalletConnectDAppConnectionProposalViewState

    init(
        getDAppConnectionProposalUseCase: WalletConnectGetDAppConnectionProposalUseCase,
        userWallets: [any UserWalletModel],
        selectedUserWallet: some UserWalletModel,
        dismissFlowAction: @escaping () -> Void
    ) {
        connectionRequestViewModel = WalletConnectDAppConnectionRequestViewModel(
            state: .loading(selectedUserWalletName: selectedUserWallet.name, walletSelectionIsAvailable: userWallets.count > 1),
            getDAppConnectionProposalUseCase: getDAppConnectionProposalUseCase,
            resolveAvailableBlockchainsUseCase: WalletConnectResolveAvailableBlockchainsUseCase(),
            selectedUserWallet: selectedUserWallet
        )
        state = .connectionRequest(connectionRequestViewModel)

        self.userWallets = userWallets
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

extension WalletConnectDAppConnectionProposalViewModel: WalletConnectDAppConnectionProposalRoutable {
    func openConnectionRequest() {
        state = .connectionRequest(connectionRequestViewModel)
    }
    
    func openDomainVerification() {
        state = .verifiedDomain
    }

    func openWalletSelector(_ selectedUserWallet: some UserWalletModel) {
        state = .walletSelector(walletSelectorViewModel)
    }

    func openNetworksSelector() {
        state = .networkSelector
    }

    func openErrorScreen(error: some Error) {
        // [REDACTED_TODO_COMMENT]
    }

    func dismiss() {
        dismissFlowAction()
    }
}
