//
//  GroupedTokenListInfoProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

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
        userTokenListManager.userTokensPublisher
            .sink { entries in
            }
            .store(in: &bag)
    }

    private func convertToSectionInfo(from storageEntries: [StorageEntry]) -> [TokenListSectionInfo] {
        let walletModels = walletModelsManager.walletModels
        return storageEntries.reduce([]) { result, entry in
            if walletModels.contains(where: { $0.blockchainNetwork == entry.blockchainNetwork }) {
                let ids = entry.walletModelIds
                let models = ids.compactMap { id in
                    walletModels.first(where: { $0.id == id })
                }

                let sectionInfo = TokenListSectionInfo(
                    sectionType: .titled(title: title(for: entry.blockchainNetwork)),
                    infoProviders: models
                )

                return result + [sectionInfo]
            }

            return result + [mapToListSectionInfo(entry)]
        }
    }

    private func mapToListSectionInfo(_ entry: StorageEntry) -> TokenListSectionInfo {
        let blockchain = entry.blockchainNetwork.blockchain
        var infoProviders = [
            TokenWithoutDerivationInfoProvider(tokenItem: .blockchain(blockchain)),
        ]

        infoProviders += entry.tokens.map {
            TokenWithoutDerivationInfoProvider(tokenItem: .token($0, blockchain))
        }

        return .init(
            sectionType: .titled(title: title(for: entry.blockchainNetwork)),
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
