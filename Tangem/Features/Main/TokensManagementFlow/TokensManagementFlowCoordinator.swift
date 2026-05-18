//
//  TokensManagementFlowCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine
import TangemLocalization
import TangemMacro
import TangemSdk
import TangemUI

final class TokensManagementFlowCoordinator: ObservableObject, FloatingSheetContentViewModel {
    @Published private(set) var state: ViewState = .chooser

    private let factory: TokensManagementFlowFactory
    private let logger: TokensManagementAnalyticsLogger
    private weak var output: TokensManagementFlowRoutable?

    private var currentAccount: (any CryptoAccountModel)?
    private var currentManageTokensViewModel: ManageTokensViewModel?
    private var currentAddCustomTokenViewModel: AddCustomTokenViewModel?
    private var currentDerivationSelectorViewModel: AddCustomTokenDerivationPathSelectorViewModel?

    init(factory: TokensManagementFlowFactory, coordinator: TokensManagementFlowRoutable) {
        self.factory = factory
        logger = factory.analyticsLogger
        output = coordinator
    }
}

// MARK: - Navigation

extension TokensManagementFlowCoordinator {
    func openOrganize() {
        logger.logButtonOrganizeTokens()
        state = .organize(factory.makeOrganizeTokensViewModel(coordinator: self))
    }

    func openAddTokens() {
        logger.logButtonAddTokens()
        Task { @MainActor in
            let accountSelector = factory.makeAccountSelectorViewModel { [weak self] cellModel in
                self?.didSelectAccount(cellModel.cryptoAccountModel)
            }
            state = .chooseAccount(accountSelector)
        }
    }

    func goBack() {
        switch state {
        case .addCustomToken:
            restoreManage()
        case .networkSelector, .derivationSelector:
            restoreAddCustomToken()
        case .derivationPathWriter:
            restoreDerivationSelector()
        case .chooser, .chooseAccount, .organize, .manage:
            close()
        }
    }

    func close() {
        Task { @MainActor in
            output?.closeTokensManagementFlow()
        }
    }

    private func didSelectAccount(_ account: any CryptoAccountModel) {
        let manageTokensViewModel = factory.makeManageTokensViewModel(for: account, coordinator: self)
        currentAccount = account
        currentManageTokensViewModel = manageTokensViewModel
        state = .manage(manageTokensViewModel)
    }

    private func restoreManage() {
        guard let manageTokensViewModel = currentManageTokensViewModel else {
            close()
            return
        }
        state = .manage(manageTokensViewModel)
    }

    private func restoreAddCustomToken() {
        guard let addCustomTokenViewModel = currentAddCustomTokenViewModel else {
            restoreManage()
            return
        }
        state = .addCustomToken(addCustomTokenViewModel)
    }

    private func restoreDerivationSelector() {
        guard let derivationSelectorViewModel = currentDerivationSelectorViewModel else {
            restoreAddCustomToken()
            return
        }
        state = .derivationSelector(derivationSelectorViewModel)
    }
}

// MARK: - OrganizeTokensRoutable

extension TokensManagementFlowCoordinator: OrganizeTokensRoutable {
    func didTapCancelButton() {
        close()
    }

    func didTapSaveButton() {
        close()
    }
}

// MARK: - ManageTokensRoutable

extension TokensManagementFlowCoordinator: ManageTokensRoutable {
    func openAddCustomToken() {
        guard let account = currentAccount else { return }
        let viewModel = factory.makeAddCustomTokenViewModel(for: account, coordinator: self)
        currentAddCustomTokenViewModel = viewModel
        state = .addCustomToken(viewModel)
    }
}

// MARK: - AddCustomTokenRoutable

extension TokensManagementFlowCoordinator: AddCustomTokenRoutable {
    func dismiss() {
        restoreManage()
    }

    func openWalletSelector(with dataSource: WalletSelectorDataSource) {
        assertionFailure(
            "Unsupported route: openWalletSelector(with:) was called in TokensManagementFlowCoordinator"
        )
    }

    func closeWalletSelector() {
        assertionFailure(
            "Unsupported route: closeWalletSelector() was called in TokensManagementFlowCoordinator"
        )
    }

    func openNetworkSelector(selectedBlockchainNetworkId: String?, blockchains: [Blockchain]) {
        let viewModel = factory.makeNetworkSelectorViewModel(
            selectedBlockchainNetworkId: selectedBlockchainNetworkId,
            blockchains: blockchains,
            delegate: self
        )
        state = .networkSelector(viewModel)
    }

    func openDerivationSelector(
        selectedDerivationOption: AddCustomTokenDerivationOption,
        defaultDerivationPath: DerivationPath,
        blockchainDerivationOptions: [AddCustomTokenDerivationOption],
        context: ManageTokensContext,
        blockchain: Blockchain
    ) {
        let viewModel = factory.makeDerivationSelectorViewModel(
            selectedDerivationOption: selectedDerivationOption,
            defaultDerivationPath: defaultDerivationPath,
            blockchainDerivationOptions: blockchainDerivationOptions,
            context: context,
            blockchain: blockchain,
            coordinator: self
        )
        currentDerivationSelectorViewModel = viewModel
        state = .derivationSelector(viewModel)
    }
}

// MARK: - AddCustomTokenNetworkSelectorDelegate

extension TokensManagementFlowCoordinator: AddCustomTokenNetworkSelectorDelegate {
    func didSelectNetwork(networkId: String) {
        currentAddCustomTokenViewModel?.setSelectedNetwork(networkId: networkId)
        restoreAddCustomToken()
    }
}

// MARK: - AddCustomTokenDerivationPathSelectorRoutable

extension TokensManagementFlowCoordinator: AddCustomTokenDerivationPathSelectorRoutable {
    func didSelectOption(_ derivationOption: AddCustomTokenDerivationOption) {
        currentAddCustomTokenViewModel?.setSelectedDerivationOption(derivationOption: derivationOption)
        restoreAddCustomToken()
    }

    func openDerivationPathWriter(
        currentDerivationPath: String,
        context: ManageTokensContext,
        blockchain: Blockchain,
        output: AddCustomTokenDerivationPathWriterOutput
    ) {
        let viewModel = factory.makeDerivationPathWriterViewModel(
            currentDerivationPath: currentDerivationPath,
            context: context,
            blockchain: blockchain,
            output: output,
            coordinator: self
        )
        state = .derivationPathWriter(viewModel)
    }
}

// MARK: - AddCustomTokenDerivationPathWriterRoutable

extension TokensManagementFlowCoordinator: AddCustomTokenDerivationPathWriterRoutable {
    func closeDerivationPathWriter() {
        restoreDerivationSelector()
    }
}

// MARK: - ViewState

extension TokensManagementFlowCoordinator {
    @RawCaseName
    @CaseFlagable
    enum ViewState {
        case chooser
        case chooseAccount(AccountSelectorViewModel)
        case organize(OrganizeTokensViewModel)
        case manage(ManageTokensViewModel)
        case addCustomToken(AddCustomTokenViewModel)
        case networkSelector(AddCustomTokenNetworksListViewModel)
        case derivationSelector(AddCustomTokenDerivationPathSelectorViewModel)
        case derivationPathWriter(AddCustomTokenDerivationPathWriterViewModel)

        var title: String {
            switch self {
            case .chooser: return Localization.mainAddAndManageTokens
            case .chooseAccount: return Localization.commonChooseAccount
            case .organize: return Localization.organizeTokensTitle
            case .manage: return Localization.addTokensTitle
            case .addCustomToken: return Localization.addCustomTokenTitle
            case .networkSelector: return Localization.customTokenNetworkSelectorTitle
            case .derivationSelector: return Localization.customTokenDerivationPath
            case .derivationPathWriter: return Localization.customTokenCustomDerivationTitle
            }
        }

        var hidesContainerHeader: Bool {
            switch self {
            case .organize: return true
            case .chooser, .chooseAccount, .manage, .addCustomToken,
                 .networkSelector, .derivationSelector, .derivationPathWriter:
                return false
            }
        }

        var canGoBack: Bool {
            switch self {
            case .addCustomToken, .networkSelector, .derivationSelector, .derivationPathWriter:
                return true
            case .chooser, .chooseAccount, .organize, .manage:
                return false
            }
        }
    }
}
