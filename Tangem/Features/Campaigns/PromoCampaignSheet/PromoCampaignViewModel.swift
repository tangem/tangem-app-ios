//
//  PromoCampaignViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemAccounts
import TangemAssets
import TangemLocalization
import TangemUI

protocol PromoCampaignRoutable: CampaignRoutable {
    func enrollInPromoCampaign(_ campaign: PromoCampaign, payoutToken: TokenSelectorItem?) -> Bool
}

final class PromoCampaignViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Injected(\.cryptoAccountsGlobalStateProvider) private var cryptoAccountsGlobalStateProvider: CryptoAccountsGlobalStateProvider
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    @Published var tokenSelectorViewModel: CampaignTokenSelectorViewModel?
    @Published private(set) var selectedTokenRowViewModel: TokenSelectorItemViewModel?
    @Published private var selectedToken: TokenSelectorItem?
    @Published private(set) var isEnrolling = false

    private static let accountScope: CampaignAccountScope = .crypto

    private let campaign: PromoCampaign
    private weak var coordinator: PromoCampaignRoutable?

    init(campaign: PromoCampaign, coordinator: PromoCampaignRoutable?) {
        self.campaign = campaign
        self.coordinator = coordinator
    }

    var title: String {
        campaign.content.title
    }

    var subtitle: String? {
        campaign.content.subtitle
    }

    var imageURL: URL? {
        campaign.content.imageURL
    }

    var blocks: [PromoCampaignContent.Block] {
        campaign.content.blocks
    }

    var learnMoreLink: PromoCampaignContent.Link? {
        campaign.content.learnMoreLink
    }

    var isAwaitingPayoutToken: Bool {
        campaign.isPayoutNeeded && selectedToken == nil
    }

    var isActionEnabled: Bool {
        !campaign.isPayoutNeeded || hasHeldPayoutToken || hasAddablePayoutToken
    }

    var actionButtonTitle: String {
        isAwaitingPayoutToken ? Localization.promoCampaignSelectToken : campaign.content.actionButtonTitle
    }

    var selectedTokenNetworkName: String {
        selectedToken?.tokenItem.networkName ?? ""
    }

    var selectedAccountViewData: SelectedAccountViewData? {
        guard
            cryptoAccountsGlobalStateProvider.globalCryptoAccountsState() == .multiple,
            let account = selectedToken?.kind.account
        else {
            return nil
        }

        return SelectedAccountViewData(
            iconData: AccountModelUtils.UI.iconViewData(accountModel: account),
            name: account.name
        )
    }

    var termsText: AttributedString? {
        guard !isAwaitingPayoutToken, let termsLink = campaign.content.termsLink else {
            return nil
        }

        var attributed = AttributedString(Localization.promoCampaignTermsAgreement(termsLink.title))
        attributed.font = DesignSystem.Font.captionMediumToken.font
        attributed.foregroundColor = DesignSystem.Color.textSecondary

        if let range = attributed.range(of: termsLink.title) {
            attributed[range].foregroundColor = DesignSystem.Color.textPrimary
            attributed[range].link = termsLink.url
        }

        return attributed
    }

    func close() {
        coordinator?.closeCampaign()
    }

    func open(_ url: URL) {
        guard !isEnrolling else {
            return
        }

        coordinator?.openLearnMore(url: url)
    }

    func performAction() {
        guard isActionEnabled, !isEnrolling else {
            return
        }

        if isAwaitingPayoutToken {
            selectToken()
        } else {
            isEnrolling = coordinator?.enrollInPromoCampaign(campaign, payoutToken: selectedToken) ?? false
        }
    }

    func selectToken() {
        guard !isEnrolling else {
            return
        }

        tokenSelectorViewModel = CampaignTokenSelectorViewModel(
            eligibleTokens: campaign.payoutTokens,
            initiallyExpandedAccount: userWalletRepository.selectedModel.flatMap { .onlyAccount(of: $0) },
            accountScope: Self.accountScope,
            onSelect: { [weak self] item in
                self?.handleSelectedToken(item)
            },
            onClose: { [weak self] in
                self?.tokenSelectorViewModel = nil
            }
        )
    }
}

// MARK: - Token selection

extension PromoCampaignViewModel {
    func handleSelectedToken(_ item: TokenSelectorItem) {
        selectedToken = item
        selectedTokenRowViewModel = TokenSelectorItemViewModelBuilder(availabilityProvider: AvailableTokenSelectorItemAvailabilityProvider())
            .mapToTokenSelectorItemViewModel(item: item, action: { _ in })
        tokenSelectorViewModel = nil
    }
}

// MARK: - Payout tokens availability

private extension PromoCampaignViewModel {
    var hasHeldPayoutToken: Bool {
        let isEligible = EligibleTokenMatcher.make(from: campaign.payoutTokens)

        return userWalletRepository.models.contains { userWalletModel in
            Self.accountScope
                .accounts(from: userWalletModel.accountModelsManager)
                .contains { $0.walletModelsManager.walletModels.contains { isEligible($0.tokenItem) } }
        }
    }

    var hasAddablePayoutToken: Bool {
        guard let userWalletModel = userWalletRepository.selectedModel else {
            return false
        }

        let tokenItemMapper = TokenItemMapper(supportedBlockchains: userWalletModel.config.supportedBlockchains)
        let eligibleTokenMapper = CampaignEligibleTokenMapper()
        let accounts = Self.accountScope.accounts(from: userWalletModel.accountModelsManager)

        return campaign.payoutTokens.contains { token in
            guard let tokenItem = eligibleTokenMapper.mapToTokenItem(token, using: tokenItemMapper) else {
                return false
            }

            return !accounts.contains { $0.userTokensManager.contains(tokenItem, derivationInsensitive: true) }
        }
    }
}

// MARK: - SelectedAccountViewData

extension PromoCampaignViewModel {
    struct SelectedAccountViewData {
        let iconData: AccountIconView.ViewData
        let name: String
    }
}
