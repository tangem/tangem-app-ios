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
    private lazy var walletSelectorViewModel: WalletConnectWalletSelectorViewModel = makeWalletSelectorViewModel()
    private lazy var networksSelectorViewModel: WalletConnectNetworksSelectorViewModel = makeNetworksSelectorViewModel()

    private let dismissFlowAction: () -> Void

    private var connectionRequestViewModelCancellable: AnyCancellable?

    @Published private(set) var state: WalletConnectDAppConnectionProposalViewState

    init(
        getDAppConnectionProposalUseCase: WalletConnectGetDAppConnectionProposalUseCase,
        connectDAppUseCase: WalletConnectConnectDAppUseCase,
        userWallets: [any UserWalletModel],
        selectedUserWallet: some UserWalletModel,
        dismissFlowAction: @escaping () -> Void
    ) {
        connectionRequestViewModel = WalletConnectDAppConnectionRequestViewModel(
            state: .loading(selectedUserWalletName: selectedUserWallet.name, walletSelectionIsAvailable: userWallets.count > 1),
            getDAppConnectionProposalUseCase: getDAppConnectionProposalUseCase,
            resolveAvailableBlockchainsUseCase: WalletConnectResolveAvailableBlockchainsUseCase(),
            connectDAppUseCase: connectDAppUseCase,
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

// MARK: - WalletConnectDAppConnectionProposalRoutable

extension WalletConnectDAppConnectionProposalViewModel: WalletConnectDAppConnectionProposalRoutable {
    func openConnectionRequest() {
        state = .connectionRequest(connectionRequestViewModel)
    }

    func openDomainVerification() {
        state = .verifiedDomain
    }

    func openWalletSelector() {
        state = .walletSelector(walletSelectorViewModel)
    }

    func openNetworksSelector() {
        guard let blockchainsAvailabilityResult = connectionRequestViewModel.cachedBlockchainsAvailabilityResult else {
            return
        }
        networksSelectorViewModel.update(with: blockchainsAvailabilityResult)
        state = .networkSelector(networksSelectorViewModel)
    }

    func openErrorScreen(error: some Error) {
        // [REDACTED_TODO_COMMENT]
    }

    func dismiss() {
        dismissFlowAction()
    }
}

// MARK: - Factory methods

extension WalletConnectDAppConnectionProposalViewModel {
    private func makeWalletSelectorViewModel() -> WalletConnectWalletSelectorViewModel {
        WalletConnectWalletSelectorViewModel(
            userWallets: userWallets,
            selectedUserWallet: connectionRequestViewModel.selectedUserWallet,
            backAction: { [weak self] in
                self?.openConnectionRequest()
            },
            userWalletSelectedAction: { [weak self] selectedUserWallet in
                self?.connectionRequestViewModel.updateSelectedUserWallet(selectedUserWallet)
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
