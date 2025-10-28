//
//  EmailDataFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct EmailDataFactory {
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
            if let totalSignedHashes = wallet.totalSignedHashes {
                let hashesData = "\(wallet.curve.rawValue) - \(totalSignedHashes)"
                data.append(.init(type: .wallet(.signedHashes), data: hashesData))
            }
        }

        return data
    }

    func makeEmailData(for mobileWallet: MobileWalletInfo) -> [EmailCollectedData] {
        [
            EmailCollectedData(type: .mobileWallet(.hasBackup), data: "\(mobileWallet.hasMnemonicBackup || mobileWallet.hasICloudBackup)"),
            EmailCollectedData(type: .mobileWallet(.hasAccessCode), data: "\(mobileWallet.accessCodeStatus.hasAccessCode)"),
        ]
    }
}
