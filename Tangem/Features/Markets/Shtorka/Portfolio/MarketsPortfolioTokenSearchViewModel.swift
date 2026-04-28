//
//  MarketsPortfolioTokenSearchViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import TangemFoundation
import TangemAssets
import TangemLocalization

final class MarketsPortfolioTokenSearchViewModel: ObservableObject {
    @Published private(set) var items: [Item] = []
    @Published private(set) var isExpanded: Bool = false

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    var collapsedItems: [Item] {
        Array(items.prefix(collapsedItemsCount))
    }

    var expandedItems: [Item] {
        Array(items.dropFirst(collapsedItemsCount))
    }

    var hasShowAll: Bool {
        items.count > collapsedItemsCount
    }

    var showAllTitle: AttributedString {
        let title = isExpanded ? Localization.feedSearchShowLessUserAssets : Localization.feedSearchShowAllUserAssets
        var string = AttributedString(title)
        string.font = .Tangem.Subheadline.medium
        string.foregroundColor = .Tangem.Text.Neutral.primary
        return string
    }

    var showAllImage: ImageType {
        isExpanded ? Assets.DesignSystem.chevronUpSmall : Assets.DesignSystem.chevronDown
    }

    var walletModelIds: [AnyHashable] {
        walletModels.map(\.id)
    }

    private var isSingleWalletWithSingleAccount: Bool {
        guard
            userWalletRepository.models.count == 1,
            let userWalletModel = userWalletRepository.models.first
        else {
            return false
        }

        return userWalletModel.accountModelsManager.accountModels.cryptoAccountsCount == 1
    }

    private let collapsedItemsCount: Int = 3

    private let walletModels: [any WalletModel]
    private let onSingleToken: () -> Void
    private let onMultipleToken: () -> Void

    init(
        walletModels: [any WalletModel],
        onSingleToken: @escaping () -> Void,
        onMultipleToken: @escaping () -> Void
    ) {
        self.walletModels = walletModels
        self.onSingleToken = onSingleToken
        self.onMultipleToken = onMultipleToken

        bind()
    }
}

// MARK: - Internal methods

extension MarketsPortfolioTokenSearchViewModel {
    func onShowAllTap() {
        isExpanded.toggle()
    }
}

// MARK: - Private methods

private extension MarketsPortfolioTokenSearchViewModel {
    func bind() {
        let groups = walletGroups(walletModels: walletModels)

        sortItemsPublisher(walletGroups: groups)
            .receiveOnMain()
            .assign(to: &$items)
    }

    func walletGroups(walletModels: [any WalletModel]) -> [WalletGroup] {
        var groups: [AnyHashable: WalletGroup] = [:]

        for walletModel in walletModels {
            let tokenItem = walletModel.tokenItem

            let groupId: AnyHashable
            if let tokenId = tokenItem.id {
                groupId = tokenId
            } else {
                groupId = tokenItem.name + tokenItem.currencySymbol
            }

            let groupWalletModels: [any WalletModel]
            if let group = groups[groupId] {
                groupWalletModels = group.walletModels + [walletModel]
            } else {
                groupWalletModels = [walletModel]
            }

            groups[groupId] = WalletGroup(id: groupId, walletModels: groupWalletModels)
        }

        return Array(groups.values)
    }

    func sortItemsPublisher(walletGroups: [WalletGroup]) -> AnyPublisher<[Item], Never> {
        guard walletGroups.isNotEmpty else {
            return Just([]).eraseToAnyPublisher()
        }

        let sortPredicate: (Item, Item) -> Bool = { lhs, rhs in
            if lhs.balance != rhs.balance {
                return lhs.balance > rhs.balance
            }
            return lhs.name < rhs.name
        }

        let initialItems = walletGroups
            .compactMap(makeItem)
            .sorted(by: sortPredicate)

        let updateItemsPublisher = items.map { item in
            updateItemPublisher(item: item)
        }

        let resortItemsPublisher = updateItemsPublisher
            .merge()
            .scan(initialItems) { currentItems, updatedItem in
                var items = currentItems
                if let index = items.firstIndex(where: { $0.id == updatedItem.id }) {
                    items[index] = updatedItem
                }
                return items.sorted(by: sortPredicate)
            }

        return Just(initialItems)
            .merge(with: resortItemsPublisher)
            .removeDuplicates { lhs, rhs in
                guard lhs.count == rhs.count else { return false }
                let lhsDictionary = Dictionary(uniqueKeysWithValues: lhs.map { ($0.id, $0.balance) })
                let rhsDictionary = Dictionary(uniqueKeysWithValues: rhs.map { ($0.id, $0.balance) })
                return lhsDictionary == rhsDictionary
            }
            .eraseToAnyPublisher()
    }

    func updateItemPublisher(item: Item) -> AnyPublisher<Item, Never> {
        item.data.balancePublishers
            .combineLatest()
            .withWeakCaptureOf(self)
            .map { viewModel, balanceTypes in
                viewModel.totalBalance(balanceTypes: balanceTypes)
            }
            .withWeakCaptureOf(self)
            .map { viewModel, balance -> Item in
                viewModel.updateItem(item, balance: balance)
            }
            .eraseToAnyPublisher()
    }

    func totalBalance(balanceTypes: [TokenBalanceType]) -> Decimal {
        balanceTypes.reduce(.zero) { total, balanceType in
            let balance = balanceType.value ?? .zero
            return total + balance
        }
    }

    func makeItem(walletGroup: WalletGroup) -> Item? {
        let walletModels = walletGroup.walletModels

        guard let walletModel = walletGroup.walletModels.first else {
            return nil
        }

        let tokenItem = walletModel.tokenItem
        let balanceTypes = walletModels.map(\.fiatAvailableBalanceProvider.balanceType)
        let balance = totalBalance(balanceTypes: balanceTypes)
        let tokenIconInfo = TokenIconInfoBuilder().build(from: tokenItem, isCustom: walletModel.isCustom)

        if isSingleWalletWithSingleAccount {
            let fiatBalancePublisher = walletModel.fiatTotalTokenBalanceProvider.balanceTypePublisher
            let cryptoBalancePublisher = walletModel.totalTokenBalanceProvider.balanceTypePublisher

            let model = MarketsPortfolioSingleTokenViewModel(
                tokenInfo: .init(
                    name: tokenItem.name,
                    currencyCode: tokenItem.currencySymbol,
                    iconInfo: tokenIconInfo
                ),
                ratePublisher: walletModel.ratePublisher,
                fiatTotalTokenBalancePublisher: fiatBalancePublisher,
                cryptoTotalTokenBalancePublisher: cryptoBalancePublisher,
                onTapAction: onSingleToken
            )

            return Item(
                id: walletGroup.id,
                balance: balance,
                data: .single(model)
            )
        } else {
            let fiatBalancePublishers = walletModels.map { $0.fiatTotalTokenBalanceProvider.balanceTypePublisher }
            let cryptoBalancePublishers = walletModels.map { $0.totalTokenBalanceProvider.balanceTypePublisher }

            let model = MarketsPortfolioMultipleTokenViewModel(
                tokenInfo: .init(
                    name: tokenItem.name,
                    count: walletModels.count,
                    currencyCode: tokenItem.currencySymbol,
                    iconInfo: tokenIconInfo
                ),
                fiatTotalTokenBalancePublishers: fiatBalancePublishers,
                cryptoTotalTokenBalancePublishers: cryptoBalancePublishers,
                onTapAction: onMultipleToken
            )

            return Item(
                id: walletGroup.id,
                balance: balance,
                data: .multiple(model)
            )
        }
    }

    func updateItem(_ item: Item, balance: Decimal) -> Item {
        Item(
            id: item.id,
            balance: balance,
            data: item.data
        )
    }
}

// MARK: - Private types

private extension MarketsPortfolioTokenSearchViewModel {
    struct WalletGroup {
        let id: AnyHashable
        let walletModels: [any WalletModel]
    }
}

// MARK: - Types

extension MarketsPortfolioTokenSearchViewModel {
    struct Item: Identifiable, Equatable {
        let id: AnyHashable
        let balance: Decimal
        let data: Data

        var name: String {
            switch data {
            case .single(let model): model.tokenName
            case .multiple(let model): model.tokenName
            }
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id
        }
    }

    enum Data {
        case single(MarketsPortfolioSingleTokenViewModel)
        case multiple(MarketsPortfolioMultipleTokenViewModel)

        var balancePublishers: [AnyPublisher<TokenBalanceType, Never>] {
            switch self {
            case .single(let model): [model.balancePublisher]
            case .multiple(let model): model.balancePublishers
            }
        }
    }
}
