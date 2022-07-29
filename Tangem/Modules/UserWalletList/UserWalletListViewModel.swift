//
//  UserWalletListViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

import struct TangemSdk.ArtworkInfo
import struct TangemSdk.Card
import struct TangemSdk.DerivationPath
import struct TangemSdk.ExtendedPublicKey
import struct TangemSdk.WalletData


// MARK: -

struct Account: Identifiable {
    var id = UUID()
    let accountId: Data
    let name: String
    let card: Card
    let extraData: CardExtraData
    let artwork: ArtworkInfo
    let keys: [Data: [DerivationPath: ExtendedPublicKey]] // encrypted
}

enum CardExtraData {
    case twin(TwinData)
    case wallet(WalletData)
}

struct TwinData {
    let pairPublicKey: Data?
}

extension Account {
    static let wallet: Account = .init(accountId: Data(hex: "00"), name: "Wallet", card: .wallet, extraData: .twin(TwinData(pairPublicKey: nil)), artwork: ArtworkInfo(id: "card_tg115", hash: "asd", date: "2022-01-01"), keys: [:])
    static let noteBtc: Account = .init(accountId: Data(hex: "01"), name: "Note", card: .noteBtc, extraData: .twin(TwinData(pairPublicKey: nil)), artwork: ArtworkInfo(id: "card_tg109", hash: "asd", date: "2022-01-01"), keys: [:])
    static let noteDoge: Account = .init(accountId: Data(hex: "01"), name: "Note", card: .noteDoge, extraData: .twin(TwinData(pairPublicKey: nil)), artwork: ArtworkInfo(id: "card_tg112", hash: "asd", date: "2022-01-01"), keys: [:])
}

// MARK: -

class UserWalletListCellViewModel: Identifiable {
    @Injected(\.cardImageLoader) var imageLoader: CardImageLoaderProtocol

    let account: Account
    let subtitle: String
    var isSelected: Bool
    var cardImage: UIImage?

    private var bag: Set<AnyCancellable> = []

    init(account: Account, subtitle: String, isSelected: Bool) {
        self.account = account
        self.subtitle = subtitle
        self.isSelected = isSelected

        imageLoader.loadImage(cid: account.card.cardId, cardPublicKey: account.card.cardPublicKey, artworkInfo: account.artwork)
            .sink { [weak self] (image, _) in
                self?.cardImage = image
            }
            .store(in: &bag)
    }
}

// MARK: -

final class UserWalletListViewModel: ObservableObject {
    // MARK: - ViewState
    var walletCellModels: [UserWalletListCellViewModel] = []
    var noteCellModels: [UserWalletListCellViewModel] = []

    // MARK: - Dependencies

    private unowned let coordinator: UserWalletListRoutable

    init(
        coordinator: UserWalletListRoutable
    ) {
        self.coordinator = coordinator

        walletCellModels = [
            .init(account: .wallet, subtitle: "3 Cards", isSelected: true),
            .init(account: .wallet, subtitle: "2 Cards", isSelected: false),
        ]

        noteCellModels = [
            .init(account: .noteBtc, subtitle: "Bitcoin", isSelected: false),
            .init(account: .noteDoge, subtitle: "Dogecoin", isSelected: false),
        ]
    }
}
