//
//  MarketsPortfolioTokenListViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemLocalization
import protocol TangemUI.FloatingSheetContentViewModel
import enum TangemUI.ThumbnailWalletViewType

final class MarketsPortfolioTokenListViewModel: ObservableObject {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    @Published var sections: [WalletSection] = []

    let barTitle = Localization.marketsPortfolioBlockTitle

    var hasWalletHeader: Bool {
        sections.count > 1
    }

    var hasAccountHeader: Bool {
        sections.contains { $0.accounts.count > 1 }
    }

    private let onSelect: (any WalletModel) -> Void
    private weak var coordinator: MarketsPortfolioTokenListRoutable?

    init(
        walletModels: [any WalletModel],
        onSelect: @escaping (any WalletModel) -> Void,
        coordinator: MarketsPortfolioTokenListRoutable
    ) {
        self.onSelect = onSelect
        self.coordinator = coordinator
        sections = makeWalletSections(walletModels: walletModels)
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
    func makeWalletSections(walletModels: [any WalletModel]) -> [WalletSection] {
        var sections: [WalletSection] = []

        for walletModel in walletModels {
            guard
                let userWalletModel = userWalletRepository.models[walletModel.userWalletId],
                let account = walletModel.account
            else {
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

        return sections
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
            accounts: [account]
        )

        sections.append(section)
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
            self?.onSelect(walletModel)
            self?.close()
        }

        return TokenRow(model: model, onTap: onTap)
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
        let onTap: () -> Void
    }
}

// MARK: - FloatingSheetContentViewModel

extension MarketsPortfolioTokenListViewModel: FloatingSheetContentViewModel {}
