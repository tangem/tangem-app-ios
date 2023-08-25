//
//  GroupedTokenListInfoProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt

// [REDACTED_TODO_COMMENT]
class GroupedTokenListInfoProvider {
    private let userTokenListManager: UserTokenListManager
    private let walletModelsManager: WalletModelsManager

    private let userWalletId: UserWalletId
    private let currentSections = CurrentValueSubject<[TokenListSectionInfo], Never>([])

    private var bag = Set<AnyCancellable>()

    init(
        userWalletId: UserWalletId = .init(with: Data()),
        userTokenListManager: UserTokenListManager,
        walletModelsManager: WalletModelsManager
    ) {
        self.userWalletId = userWalletId
        self.userTokenListManager = userTokenListManager
        self.walletModelsManager = walletModelsManager

        bind()
    }

    private func bind() {
        // [REDACTED_TODO_COMMENT]
        userTokenListManager.userTokensPublisher
            .removeDuplicates()
            .combineLatest(walletModelsManager.walletModelsPublisher.removeDuplicates())
            .map(convertToSectionInfo(from:and:))
            .assign(to: \.value, on: currentSections, ownership: .weak)
            .store(in: &bag)
    }

    private func convertToSectionInfo(from storageEntries: [StorageEntry], and walletModels: [WalletModel]) -> [TokenListSectionInfo] {
        return storageEntries.reduce([]) { result, entry in
            if walletModels.contains(where: { $0.blockchainNetwork == entry.blockchainNetwork }) {
                let ids = entry.walletModelIds
                let models: [DefaultTokenItemInfoProvider] = ids.compactMap { id in
                    guard let model = walletModels.first(where: { $0.id == id }) else {
                        return nil
                    }

                    return DefaultTokenItemInfoProvider(walletModel: model)
                }

                let sectionInfo = TokenListSectionInfo(
                    id: entry.blockchainNetwork.hashValue,
                    sectionType: .titled(title: title(for: entry.blockchainNetwork)),
                    infoProviders: models
                )

                return result + [sectionInfo]
            }

            return result + [mapToListSectionInfo(entry)]
        }
    }

    private func mapToListSectionInfo(_ entry: StorageEntry) -> TokenListSectionInfo {
        let blockchainNetwork = entry.blockchainNetwork
        var infoProviders = [
            TokenWithoutDerivationInfoProvider(
                id: WalletModel.Id(blockchainNetwork: blockchainNetwork, amountType: .coin).id,
                tokenItem: .blockchain(blockchainNetwork.blockchain)
            ),
        ]

        infoProviders += entry.tokens.map {
            TokenWithoutDerivationInfoProvider(
                id: WalletModel.Id(blockchainNetwork: blockchainNetwork, amountType: .token(value: $0)).id,
                tokenItem: .token($0, blockchainNetwork.blockchain)
            )
        }

        return .init(
            id: entry.blockchainNetwork.hashValue,
            sectionType: .titled(title: title(for: blockchainNetwork)),
            infoProviders: infoProviders
        )
    }

    private func title(for blockchainNetwork: BlockchainNetwork) -> String {
        Localization.walletNetworkGroupTitle(blockchainNetwork.blockchain.displayName)
    }
}

extension GroupedTokenListInfoProvider: TokenListInfoProvider {
    var sectionsPublisher: AnyPublisher<[TokenListSectionInfo], Never> {
        currentSections.eraseToAnyPublisher()
    }
}
