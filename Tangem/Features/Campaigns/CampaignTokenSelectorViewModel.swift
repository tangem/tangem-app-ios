//
//  CampaignTokenSelectorViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI
import TangemLocalization

final class CampaignTokenSelectorViewModel: ObservableObject, Identifiable {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    let tokenSelectorViewModel: TokenSelectorViewModel
    let accountScope: CampaignAccountScope

    @Published private(set) var eligibleTokenRows: [EligibleTokenRowViewData] = []
    @Published private(set) var addTokenFlowViewModel: AddTokenFlowRedesignedViewModel?

    private let eligibleTokens: [CampaignEligibleToken]
    private let onSelect: (TokenSelectorItem) -> Void
    private let onClose: () -> Void

    init(
        eligibleTokens: [CampaignEligibleToken],
        initiallyExpandedAccount: TokenSelectorViewModel.InitiallyExpandedAccount?,
        accountScope: CampaignAccountScope = .cryptoAndJoint,
        onSelect: @escaping (TokenSelectorItem) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.eligibleTokens = eligibleTokens
        self.accountScope = accountScope
        self.onSelect = onSelect
        self.onClose = onClose

        let isEligible = EligibleTokenMatcher.make(from: eligibleTokens)
        tokenSelectorViewModel = TokenSelectorViewModel.common(
            walletsProvider: FilteredTokenSelectorWalletsProvider(
                base: accountScope.walletsProvider,
                isIncluded: { isEligible($0.tokenItem) }
            ),
            availabilityProvider: AvailableTokenSelectorItemAvailabilityProvider(),
            initiallyExpandedAccount: initiallyExpandedAccount
        )

        tokenSelectorViewModel.setup(with: self)
        resolveTokensToAdd()
    }

    func dismiss() {
        onClose()
    }

    func addToken(_ tokenItem: TokenItem) {
        Task { @MainActor [self] in
            let configuration = AddTokenFlowConfiguration(
                getAvailableTokenItems: { _ in [tokenItem] },
                postAddBehavior: .executeAction { [weak self] _, _ in
                    self?.addTokenFlowViewModel = nil
                    self?.resolveTokensToAdd()
                },
                accountFilter: accountScope.addTokenAccountFilter
            )

            guard let viewModel = AddTokenFlowRedesignedViewModel(
                tokenItem: tokenItem,
                userWalletModels: walletModelsWithSelectedFirst,
                configuration: configuration,
                coordinator: self
            ) else {
                presentErrorToast(with: Localization.commonSomethingWentWrong)
                return
            }

            addTokenFlowViewModel = viewModel
        }
    }

    func dismissAddToken() {
        addTokenFlowViewModel = nil
    }
}

// MARK: - EligibleTokenRowViewData

extension CampaignTokenSelectorViewModel {
    struct EligibleTokenRowViewData: Identifiable {
        let tokenItem: TokenItem
        let iconInfo: TokenIconInfo
        let name: String
        let symbol: String
        let networkName: String

        var id: TokenItem { tokenItem }
    }
}

// MARK: - Private

private extension CampaignTokenSelectorViewModel {
    var walletModelsWithSelectedFirst: [any UserWalletModel] {
        guard let selectedModel = userWalletRepository.selectedModel else {
            return userWalletRepository.models
        }

        let otherModels = userWalletRepository.models.filter { $0.userWalletId != selectedModel.userWalletId }
        return [selectedModel] + otherModels
    }

    func resolveTokensToAdd() {
        guard let userWalletModel = userWalletRepository.selectedModel else {
            return
        }

        let mapper = TokenItemMapper(supportedBlockchains: userWalletModel.config.supportedBlockchains)
        let eligibleTokenMapper = CampaignEligibleTokenMapper()
        let accounts = accountScope.accounts(from: userWalletModel.accountModelsManager)

        eligibleTokenRows = eligibleTokens.compactMap { token in
            guard let tokenItem = eligibleTokenMapper.mapToTokenItem(token, using: mapper) else {
                return nil
            }

            let isAlreadyAdded = accounts.contains {
                $0.userTokensManager.contains(tokenItem, derivationInsensitive: true)
            }

            guard !isAlreadyAdded else {
                return nil
            }

            return EligibleTokenRowViewData(
                tokenItem: tokenItem,
                iconInfo: TokenIconInfoBuilder().build(from: tokenItem, isCustom: false),
                name: tokenItem.name,
                symbol: tokenItem.currencySymbol,
                networkName: tokenItem.networkName
            )
        }
    }
}

// MARK: - TokenSelectorViewModelOutput

extension CampaignTokenSelectorViewModel: TokenSelectorViewModelOutput {
    func userDidSelect(item: TokenSelectorItem) {
        onSelect(item)
    }
}

// MARK: - AddTokenFlowRedesignedRoutable

extension CampaignTokenSelectorViewModel: AddTokenFlowRedesignedRoutable {
    func close() {
        addTokenFlowViewModel = nil
    }

    func presentSuccessToast(with text: String) {
        Toast(view: SuccessToast(text: text))
            .present(layout: .top(padding: Constants.toastTopPadding), type: .temporary())
    }

    func presentErrorToast(with text: String) {
        Toast(view: WarningToast(text: text))
            .present(layout: .top(padding: Constants.toastTopPadding), type: .temporary())
    }

    func addTokenFlowShowGetToken(for tokenItem: TokenItem, accountSelectorCell: AccountSelectorCellModel) {
        assertionFailure("Campaign token selector uses .executeAction post-add behavior; showGetToken is not expected")
    }
}

// MARK: - Constants

private extension CampaignTokenSelectorViewModel {
    enum Constants {
        static let toastTopPadding: CGFloat = 52
    }
}
