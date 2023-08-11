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
    private let walletModelsManager: WalletModelsManager

    private let userWalletId: UserWalletId
    private let currentSections = CurrentValueSubject<[TokenListSectionInfo], Never>([])

    init(userWalletId: UserWalletId = .init(with: Data()), walletModelsManager: WalletModelsManager) {
        self.userWalletId = userWalletId
        self.walletModelsManager = walletModelsManager

        bind()
    }

    private func bind() {
        var repoSubscription: AnyCancellable?
        repoSubscription = walletModelsManager.walletModelsPublisher
            .map { Dictionary(grouping: $0, by: { $0.blockchainNetwork }) }
            .map(convertToSectionInfo(_:))
            .sink { [weak self] sections in
                self?.currentSections.send(sections)
                withExtendedLifetime(repoSubscription) {}
            }
    }

    private func convertToSectionInfo(_ dict: [BlockchainNetwork: [WalletModel]]) -> [TokenListSectionInfo] {
        dict.map {
            TokenListSectionInfo(
                sectionType: .titled(
                    title: Localization.walletNetworkGroupTitle($0.key.blockchain.displayName)
                ),
                infoProviders: $0.value
            )
        }
    }
}

extension GroupedTokenListInfoProvider: TokenListInfoProvider {
    var sectionsPublisher: AnyPublisher<[TokenListSectionInfo], Never> {
        currentSections.eraseToAnyPublisher()
    }
}
