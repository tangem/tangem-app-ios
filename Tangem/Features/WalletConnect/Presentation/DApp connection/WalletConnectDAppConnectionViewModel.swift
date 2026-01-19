//
//  WalletConnectDAppConnectionViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemLocalization
import TangemUIUtils
import TangemFoundation

@MainActor
final class WalletConnectDAppConnectionViewModel: ObservableObject {
    private let hapticFeedbackGenerator: any WalletConnectHapticFeedbackGenerator
    private let userWallets: [any UserWalletModel]
    private var selectedUserWallet: any UserWalletModel
    private var selectedAccount: (any CryptoAccountModel)?

    private let connectionRequestViewModel: WalletConnectDAppConnectionRequestViewModel
    private lazy var walletSelectorViewModel: WalletConnectWalletSelectorViewModel = makeWalletSelectorViewModel()
    private lazy var networksSelectorViewModel: WalletConnectNetworksSelectorViewModel = makeNetworksSelectorViewModel()
    private lazy var accountSelectorViewModel: AccountSelectorViewModel? = makeAccountSelectorViewModel()

    private let dismissFlowAction: () -> Void

    private var bag: Set<AnyCancellable>

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

        selectedAccount = selectedUserWallet.accountModelsManager.cryptoAccountModels.first
        bag = []

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
            .store(in: &bag)
    }
}

// MARK: - WalletConnectDAppConnectionRoutable

extension WalletConnectDAppConnectionViewModel: WalletConnectDAppConnectionRoutable {
    func openConnectionRequest() {
        if FeatureProvider.isAvailable(.accounts) {
            connectionRequestViewModel.updateSelectedAccount(selectedAccount, selectedUserWallet: selectedUserWallet)
        } else {
            connectionRequestViewModel.updateSelectedUserWallet(selectedUserWallet)
        }

        state = .connectionRequest(connectionRequestViewModel)
    }

    func openVerifiedDomain() {
        let viewModel = WalletConnectDAppDomainVerificationViewModel(
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
            .store(in: &bag)

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

    func openAccountSelector() {
        guard let accountSelectorViewModel else { return }

        state = .connectionTarget(accountSelectorViewModel)
    }

    func displaySuccessfulDAppConnection(with dAppName: String) {
        WalletConnectModuleFactory.makeSuccessToast(with: Localization.wcConnectedTo(dAppName))
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
                if FeatureProvider.isAvailable(.accounts) {
                    self?.connectionRequestViewModel.updateSelectedBlockchainsForAccount(selectedBlockchains)
                } else {
                    self?.connectionRequestViewModel.updateSelectedBlockchainsForWallet(selectedBlockchains)
                }
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
            .store(in: &bag)

        return viewModel
    }

    private func makeAccountSelectorViewModel() -> AccountSelectorViewModel? {
        guard let selectedAccount else { return nil }

        let viewModel = AccountSelectorViewModel(
            selectedItem: selectedAccount,
            userWalletModels: userWallets,
            onSelect: { [weak self] result in
                guard let self else { return }

                switch result {
                case .wallet(let walletModel):
                    self.selectedAccount = walletModel.mainAccount
                    selectedUserWallet = walletModel.domainModel

                case .account(let accountModel):
                    self.selectedAccount = accountModel.domainModel

                    selectedUserWallet = userWallets.first {
                        $0.accountModelsManager.accountModels.contains {
                            WCAccountFinder.firstAvailableCryptoAccountModel(from: $0).id == accountModel.domainModel.id
                        }
                    } ?? selectedUserWallet
                }

                openConnectionRequest()
            }
        )

        return viewModel
    }
}
