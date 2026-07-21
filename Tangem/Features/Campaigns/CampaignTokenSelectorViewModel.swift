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

    @Published private(set) var eligibleTokenRows: [EligibleTokenRowViewData] = []
    @Published private(set) var addTokenFlowViewModel: AddTokenFlowRedesignedViewModel?

    private let eligibleTokens: [BannerPromotion.Response.Token]
    private let onSelect: (TokenSelectorItem) -> Void
    private let onClose: () -> Void

    init(
        eligibleTokens: [BannerPromotion.Response.Token],
        onSelect: @escaping (TokenSelectorItem) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.eligibleTokens = eligibleTokens
        self.onSelect = onSelect
        self.onClose = onClose

        tokenSelectorViewModel = TokenSelectorViewModel.common(
            walletsProvider: EligibleTokensWalletsProvider(
                base: .common(),
                isEligible: EligibleTokenMatcher.make(from: eligibleTokens)
            ),
            availabilityProvider: AvailableTokenSelectorItemAvailabilityProvider()
        )

        tokenSelectorViewModel.setup(with: self)
        resolveTokensToAdd()
    }

    func dismiss() {
        onClose()
    }

    func addToken(_ tokenItem: TokenItem) {
        Task { @MainActor in
            let configuration = AddTokenFlowConfiguration(
                getAvailableTokenItems: { _ in [tokenItem] },
                postAddBehavior: .executeAction { [weak self] _, _ in
                    self?.addTokenFlowViewModel = nil
                    self?.resolveTokensToAdd()
                }
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
        let accounts = userWalletModel.accountModelsManager.cryptoAccountModels

        eligibleTokenRows = eligibleTokens.compactMap { token in
            guard let tokenId = token.tokenId, let decimals = token.decimals else {
                return nil
            }

            let network = NetworkModel(
                networkId: token.networkId,
                contractAddress: token.tokenAddress,
                decimalCount: decimals
            )

            let tokenItem = mapper.mapToTokenItem(
                id: tokenId,
                name: token.tokenName,
                symbol: token.tokenSymbol,
                network: network
            )

            guard let tokenItem else {
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
