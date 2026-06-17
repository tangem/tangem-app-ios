//
//  TokensManagementFlowFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemSdk

final class TokensManagementFlowFactory {
    private(set) var analyticsLogger: TokensManagementAnalyticsLogger
    private let userWalletModel: UserWalletModel

    init(userWalletModel: UserWalletModel, analyticsLogger: TokensManagementAnalyticsLogger) {
        self.userWalletModel = userWalletModel
        self.analyticsLogger = analyticsLogger
    }

    @MainActor
    func makeFlowViewModel(coordinator: TokensManagementFlowRoutable) -> TokensManagementFlowCoordinator {
        TokensManagementFlowCoordinator(factory: self, coordinator: coordinator)
    }

    func makeOrganizeTokensViewModel(coordinator: OrganizeTokensRoutable) -> OrganizeTokensViewModel {
        OrganizeTokensViewModel(
            userWalletModel: userWalletModel,
            coordinator: coordinator,
            analyticsLogger: analyticsLogger
        )
    }

    @MainActor
    func makeAccountSelectorViewModel(
        onSelect: @escaping (AccountSelectorCellModel) -> Void
    ) -> AccountSelectorViewModel {
        AccountSelectorViewModel(userWalletModel: userWalletModel, onSelect: onSelect)
    }

    func makeManageTokensViewModel(
        for account: any CryptoAccountModel,
        coordinator: ManageTokensRoutable
    ) -> ManageTokensViewModel {
        let context = makeContext(for: account)
        let adapter = ManageTokensAdapter(
            settings: .init(
                existingCurves: userWalletModel.config.existingCurves,
                supportedBlockchains: Set(userWalletModel.config.supportedBlockchains),
                hardwareLimitationUtil: HardwareLimitationsUtil(config: userWalletModel.config),
                analyticsSourceRawValue: Analytics.ParameterValue.main.rawValue,
                context: context
            )
        )
        return ManageTokensViewModel(
            adapter: adapter,
            context: context,
            coordinator: coordinator,
            presentsAlertsViaOverlay: true
        )
    }

    func makeAddCustomTokenViewModel(
        for account: any CryptoAccountModel,
        coordinator: AddCustomTokenRoutable
    ) -> AddCustomTokenViewModel {
        let config = userWalletModel.config
        let supportedBlockchains = Array(config.supportedBlockchains)
            .filter { $0.curve.supportsDerivation && $0.isSupportedNetworkCustomDerivation }
            .sorted(by: \.displayName)

        let settings = AddCustomTokenViewModel.ManageTokensSettings(
            supportedBlockchains: supportedBlockchains,
            hdWalletsSupported: config.hasFeature(.hdWallets),
            derivationStyle: config.derivationStyle,
            analyticsSourceRawValue: Analytics.ParameterValue.main.rawValue
        )

        return AddCustomTokenViewModel(
            settings: settings,
            context: makeContext(for: account),
            coordinator: coordinator
        )
    }

    func makeNetworkSelectorViewModel(
        selectedBlockchainNetworkId: String?,
        blockchains: [Blockchain],
        delegate: AddCustomTokenNetworkSelectorDelegate
    ) -> AddCustomTokenNetworksListViewModel {
        let viewModel = AddCustomTokenNetworksListViewModel(
            selectedBlockchainNetworkId: selectedBlockchainNetworkId,
            blockchains: blockchains
        )
        viewModel.delegate = delegate
        return viewModel
    }

    func makeDerivationSelectorViewModel(
        selectedDerivationOption: AddCustomTokenDerivationOption,
        defaultDerivationPath: DerivationPath,
        blockchainDerivationOptions: [AddCustomTokenDerivationOption],
        context: ManageTokensContext,
        blockchain: Blockchain,
        coordinator: AddCustomTokenDerivationPathSelectorRoutable
    ) -> AddCustomTokenDerivationPathSelectorViewModel {
        AddCustomTokenDerivationPathSelectorViewModel(
            selectedDerivationOption: selectedDerivationOption,
            defaultDerivationPath: defaultDerivationPath,
            blockchainDerivationOptions: blockchainDerivationOptions,
            context: context,
            blockchain: blockchain,
            coordinator: coordinator
        )
    }

    func makeDerivationPathWriterViewModel(
        currentDerivationPath: String,
        context: ManageTokensContext,
        blockchain: Blockchain,
        output: AddCustomTokenDerivationPathWriterOutput,
        coordinator: AddCustomTokenDerivationPathWriterRoutable
    ) -> AddCustomTokenDerivationPathWriterViewModel {
        AddCustomTokenDerivationPathWriterViewModel(
            currentDerivationPath: currentDerivationPath,
            context: context,
            blockchain: blockchain,
            output: output,
            coordinator: coordinator
        )
    }

    private func makeContext(for account: any CryptoAccountModel) -> ManageTokensContext {
        CommonManageTokensContext(
            accountModelsManager: userWalletModel.accountModelsManager,
            currentAccount: account
        )
    }
}
