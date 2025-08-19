//
//  CardEmailDataFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemHotSdk

struct CardEmailDataFactory {
    func makeEmailData(for card: CardDTO, walletData: WalletData?) -> [EmailCollectedData] {
        var data: [EmailCollectedData] = [
            .init(type: .card(.cardId), data: card.cardId),
            .init(type: .card(.firmwareVersion), data: card.firmwareVersion.stringValue),
            .init(type: .card(.linkedCardsCount), data: "\(card.backupStatus.flatMap { $0.linkedCardsCount } ?? 0)"),
            .init(type: .card(.backupCardsCount), data: "\(card.backupStatus.flatMap { $0.backupCardsCount } ?? 0)"),
            .init(type: .wallet(.hasSeedPhrase), data: "\(card.wallets.contains(where: { $0.isImported ?? false }))"),
        ]

        if let walletData = walletData {
            data.append(.init(type: .card(.cardBlockchain), data: walletData.blockchain))
        }

        for wallet in card.wallets {
            if let totalSignedHahes = wallet.totalSignedHashes {
                let hashesData = "\(wallet.curve.rawValue) - \(totalSignedHahes)"
                data.append(.init(type: .wallet(.signedHashes), data: hashesData))
            }
        }

        return data
    }

    func makeEmailData(for hotWallet: HotWalletInfo) -> [EmailCollectedData] {
        #warning("Provide implementation")
        return []
    }
}
