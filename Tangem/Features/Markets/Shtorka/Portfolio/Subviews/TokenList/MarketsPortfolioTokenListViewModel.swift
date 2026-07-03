//
//  MarketsPortfolioTokenListViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemLocalization
import protocol TangemUI.FloatingSheetContentViewModel
import enum TangemUI.ThumbnailWalletViewType
import struct TangemFoundation.UserWalletId

final class MarketsPortfolioTokenListViewModel: ObservableObject {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    @Published var sections: [WalletSection] = []

    let barTitle = Localization.marketsPortfolioBlockTitle
    var addTokenPromo: AddTokenPromo?

    var hasWalletHeader: Bool {
        sections.count > 1 || hasAccountHeader
    }

    var hasAccountHeader: Bool {
        sections.contains(where: \.walletHasMultipleAccounts)
    }

    private let onSelect: (any WalletModel) -> Void
    private let dismissesOnSelect: Bool
    private weak var coordinator: MarketsPortfolioTokenListRoutable?

    init(
        walletModels: [any WalletModel],
        underivedTokens: [UnderivedToken] = [],
        addTokenPromo: AddTokenPromo? = nil,
        dismissesOnSelect: Bool = true,
        onSelect: @escaping (any WalletModel) -> Void,
        coordinator: MarketsPortfolioTokenListRoutable
    ) {
        self.onSelect = onSelect
        self.dismissesOnSelect = dismissesOnSelect
        self.coordinator = coordinator
        self.addTokenPromo = addTokenPromo
        sections = makeWalletSections(walletModels: walletModels, underivedTokens: underivedTokens)
    }
}

// MARK: - Internal methods

extension MarketsPortfolioTokenListViewModel {
    func onCloseTap() {
        close()
    }
}

// MARK: - Private methods

private extension MarketsPortfolioTokenListViewModel {
    func makeWalletSections(walletModels: [any WalletModel], underivedTokens: [UnderivedToken]) -> [WalletSection] {
        var sections: [WalletSection] = []

        for walletModel in walletModels {
            guard let userWalletModel = userWalletRepository.models[walletModel.userWalletId] else {
                continue
            }

            // `WalletModel.account` is a weak reference, so fall back to resolving the owning account
            // from the wallet's account models to avoid silently dropping rows.
            guard let account = walletModel.account ?? resolveAccount(for: walletModel, in: userWalletModel) else {
                continue
            }

            let walletSection = sections.first { $0.id == AnyHashable(walletModel.userWalletId) }

            if let walletSection {
                update(
                    in: &sections,
                    walletSection: walletSection,
                    walletModel: walletModel,
                    account: account
                )
            } else {
                insert(
                    to: &sections,
                    userWalletModel: userWalletModel,
                    walletModel: walletModel,
                    account: account
                )
            }
        }

        // Tokens that exist in the portfolio but whose addresses aren't derived yet have no wallet model,
        // so they never come through `walletModels`. Show them as non-tappable "No address" rows instead
        // of silently disappearing (which left the sheet empty until a manual sync).
        for underived in underivedTokens {
            appendNoAddressRow(to: &sections, underived: underived)
        }

        return sections
    }

    func appendNoAddressRow(to sections: inout [WalletSection], underived: UnderivedToken) {
        let row = makeNoAddressTokenRow(tokenItem: underived.tokenItem)
        let walletId = AnyHashable(underived.userWalletId)

        guard let walletIdx = sections.firstIndex(where: { $0.id == walletId }) else {
            sections.append(
                WalletSection(
                    id: walletId,
                    title: underived.walletName,
                    thumbnail: underived.walletThumbnail,
                    walletHasMultipleAccounts: underived.walletHasMultipleAccounts,
                    accounts: [
                        AccountSection(
                            id: underived.accountId,
                            title: underived.accountName,
                            icon: underived.accountIcon,
                            tokenRows: [row]
                        ),
                    ]
                )
            )
            return
        }

        if let accountIdx = sections[walletIdx].accounts.firstIndex(where: { $0.id == underived.accountId }) {
            sections[walletIdx].accounts[accountIdx].tokenRows.append(row)
        } else {
            sections[walletIdx].accounts.append(
                AccountSection(
                    id: underived.accountId,
                    title: underived.accountName,
                    icon: underived.accountIcon,
                    tokenRows: [row]
                )
            )
        }
    }

    func update(
        in sections: inout [WalletSection],
        walletSection: WalletSection,
        walletModel: any WalletModel,
        account: any CryptoAccountModel
    ) {
        guard let walletIdx = sections.firstIndex(where: { $0.id == walletSection.id }) else {
            return
        }

        let tokenRow = makeTokenRow(walletModel: walletModel)
        let accountIdx = sections[walletIdx].accounts.firstIndex { $0.id == AnyHashable(account.id) }

        if let accountIdx {
            sections[walletIdx].accounts[accountIdx].tokenRows.append(tokenRow)
        } else {
            let newAccount = AccountSection(
                id: account.id,
                title: account.name,
                icon: account.icon.erased,
                tokenRows: [tokenRow]
            )
            sections[walletIdx].accounts.append(newAccount)
        }
    }

    func insert(
        to sections: inout [WalletSection],
        userWalletModel: any UserWalletModel,
        walletModel: any WalletModel,
        account: any CryptoAccountModel
    ) {
        let tokenRow = makeTokenRow(walletModel: walletModel)

        let account = AccountSection(
            id: account.id,
            title: account.name,
            icon: account.icon.erased,
            tokenRows: [tokenRow]
        )

        let section = WalletSection(
            id: walletModel.userWalletId,
            title: userWalletModel.name,
            thumbnail: userWalletModel.config.walletThumbnailType,
            walletHasMultipleAccounts: userWalletModel.accountModelsManager.cryptoAccountModels.count > 1,
            accounts: [account]
        )

        sections.append(section)
    }

    func resolveAccount(for walletModel: any WalletModel, in userWalletModel: any UserWalletModel) -> (any CryptoAccountModel)? {
        userWalletModel.accountModelsManager.cryptoAccountModels.first { account in
            account.walletModelsManager.walletModels.contains { $0.id == walletModel.id }
        }
    }

    func makeTokenRow(walletModel: any WalletModel) -> TokenRow {
        let fiatBalancePublisher = walletModel.fiatTotalTokenBalanceProvider.balanceTypePublisher
        let cryptoBalancePublisher = walletModel.totalTokenBalanceProvider.balanceTypePublisher

        let tokenItem = walletModel.tokenItem
        let tokenIconInfo = TokenIconInfoBuilder().build(from: tokenItem, isCustom: walletModel.isCustom)
        let networkName = "\(tokenItem.networkName) \(Localization.wcCommonNetwork.lowercased())"

        let model = MarketsPortfolioTokenListRowViewModel(
            tokenInfo: .init(
                name: tokenItem.name,
                networkName: networkName,
                currencyCode: tokenItem.currencySymbol,
                iconInfo: tokenIconInfo
            ),
            fiatTotalTokenBalancePublisher: fiatBalancePublisher,
            cryptoTotalTokenBalancePublisher: cryptoBalancePublisher
        )

        let onTap: () -> Void = { [weak self] in
            guard let self else { return }

            if dismissesOnSelect {
                close()
            }

            onSelect(walletModel)
        }

        return TokenRow(model: model, onTap: onTap)
    }

    func makeNoAddressTokenRow(tokenItem: TokenItem) -> TokenRow {
        let tokenIconInfo = TokenIconInfoBuilder().build(from: tokenItem, isCustom: tokenItem.token?.isCustom ?? false)
        let networkName = "\(tokenItem.networkName) \(Localization.wcCommonNetwork.lowercased())"

        let model = MarketsPortfolioTokenListRowViewModel(
            noAddressTokenInfo: .init(
                name: tokenItem.name,
                networkName: networkName,
                currencyCode: tokenItem.currencySymbol,
                iconInfo: tokenIconInfo
            )
        )

        return TokenRow(model: model, onTap: nil)
    }
}

// MARK: - Navigation

private extension MarketsPortfolioTokenListViewModel {
    func close() {
        Task { @MainActor [coordinator] in
            coordinator?.closePortfolioTokenList()
        }
    }
}

// MARK: - Types

extension MarketsPortfolioTokenListViewModel {
    struct WalletSection {
        let id: AnyHashable
        let title: String
        let thumbnail: ThumbnailWalletViewType?
        let walletHasMultipleAccounts: Bool
        var accounts: [AccountSection]
    }

    struct AccountSection {
        let id: AnyHashable
        let title: String
        let icon: AccountModel.Icon
        var tokenRows: [TokenRow]
    }

    struct TokenRow {
        let model: MarketsPortfolioTokenListRowViewModel
        let onTap: (() -> Void)?
    }

    struct AddTokenPromo {
        let iconURL: URL
        let action: () -> Void
    }

    /// A portfolio token whose address isn't derived yet, so it has no wallet model.
    /// Rendered as a non-tappable "No address" row.
    struct UnderivedToken {
        let userWalletId: UserWalletId
        let walletName: String
        let walletThumbnail: ThumbnailWalletViewType?
        let walletHasMultipleAccounts: Bool
        let accountId: AnyHashable
        let accountName: String
        let accountIcon: AccountModel.Icon
        let tokenItem: TokenItem
    }
}

// MARK: - FloatingSheetContentViewModel

extension MarketsPortfolioTokenListViewModel: FloatingSheetContentViewModel {}
