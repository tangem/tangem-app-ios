//
//  WalletConnectDAppConnectionViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemUI

@MainActor
final class WalletConnectDAppConnectionViewModel: ObservableObject {
    private let hapticFeedbackGenerator: any WalletConnectHapticFeedbackGenerator
    private let userWallets: [any UserWalletModel]
    private var selectedUserWallet: any UserWalletModel

    private let connectionRequestViewModel: WalletConnectDAppConnectionRequestViewModel
    private lazy var walletSelectorViewModel: WalletConnectWalletSelectorViewModel = makeWalletSelectorViewModel()
    private lazy var networksSelectorViewModel: WalletConnectNetworksSelectorViewModel = makeNetworksSelectorViewModel()

    private let dismissFlowAction: () -> Void

    private var cancellables: Set<AnyCancellable>

    @Published private(set) var state: WalletConnectDAppConnectionViewState

    init(
        connectionRequestViewModel: WalletConnectDAppConnectionRequestViewModel,
        hapticFeedbackGenerator: some WalletConnectHapticFeedbackGenerator,
        userWallets: [any UserWalletModel],
        selectedUserWallet: some UserWalletModel,
        dismissFlowAction: @escaping () -> Void
    ) {
        self.connectionRequestViewModel = connectionRequestViewModel
        state = .connectionRequest(connectionRequestViewModel)

        self.hapticFeedbackGenerator = hapticFeedbackGenerator
        self.userWallets = userWallets
        self.selectedUserWallet = selectedUserWallet

        self.dismissFlowAction = dismissFlowAction

        cancellables = []

        setupConnectionRequestViewModel()
    }

    func loadDAppProposal() {
        connectionRequestViewModel.loadDAppConnectionProposal()
    }

    private func setupConnectionRequestViewModel() {
        connectionRequestViewModel.coordinator = self

        connectionRequestViewModel
            .$state
            .map { state in
                (
                    state.connectionRequestSection,
                    state.dAppVerificationWarningSection,
                    state.networksWarningSection,
                    state.connectButton.isLoading
                )
            }
            .removeDuplicates(by: ==)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}

// MARK: - WalletConnectDAppConnectionRoutable

extension WalletConnectDAppConnectionViewModel: WalletConnectDAppConnectionRoutable {
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
        connectAnywayAction: @escaping () async -> Void
    ) {
        let openConnectionRequestAction: () -> Void = { [weak self] in
            self?.openConnectionRequest()
        }

        let viewModel = WalletConnectDAppDomainVerificationViewModel(
            warningVerificationStatus: verificationStatus,
            closeAction: openConnectionRequestAction,
            connectAnywayAction: connectAnywayAction
        )

        viewModel
            .$state
            .map { state in
                state.buttons
            }
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

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

    func displaySuccessfulDAppConnection(with dAppName: String) {
        WalletConnectModuleFactory.makeSuccessToast(with: "\(dAppName) has been connected")
            .present(layout: .top(padding: 20), type: .temporary())
    }

    func display(proposalLoadingError: WalletConnectDAppProposalLoadingError) {
        if let errorToast = WalletConnectModuleFactory.makeDAppProposalLoadingErrorToast(proposalLoadingError) {
            errorToast.present(layout: .top(padding: 20), type: .temporary())
            // [REDACTED_USERNAME], since we can't do anything unless proposal loads successfully, we need to dismiss entire flow...
            dismiss()
        }

        if let errorViewModel = WalletConnectModuleFactory.makeDAppProposalLoadingErrorViewModel(
            proposalLoadingError,
            closeAction: { [weak self] in
                self?.dismiss()
            }
        ) {
            state = .error(errorViewModel)
        }
    }

    func display(proposalApprovalError: WalletConnectDAppProposalApprovalError) {
        if let errorToast = WalletConnectModuleFactory.makeDAppProposalApprovalErrorToast(proposalApprovalError) {
            errorToast.present(layout: .top(padding: 20), type: .temporary())
        }

        if let errorViewModel = WalletConnectModuleFactory.makeDAppProposalApprovalErrorViewModel(
            proposalApprovalError,
            closeAction: { [weak self] in
                self?.dismiss()
            }
        ) {
            state = .error(errorViewModel)
        }
    }

    func display(dAppPersistenceError: WalletConnectDAppPersistenceError) {
        let errorToast = WalletConnectModuleFactory.makeDAppPersistenceErrorToast(dAppPersistenceError)
        errorToast.present(layout: .top(padding: 20), type: .temporary())
    }

    func dismiss() {
        dismissFlowAction()
    }
}

// MARK: - Factory methods

extension WalletConnectDAppConnectionViewModel {
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
        let viewModel = WalletConnectNetworksSelectorViewModel(
            backAction: { [weak self] in
                self?.openConnectionRequest()
            },
            doneAction: { [weak self] selectedBlockchains in
                self?.connectionRequestViewModel.updateSelectedBlockchains(selectedBlockchains)
                self?.openConnectionRequest()
            }
        )

        viewModel
            .$state
            .map { state in
                state.doneButton.isEnabled
            }
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        return viewModel
    }
}
