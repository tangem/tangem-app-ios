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
    static func wallet(index: Int) -> Account {
        .init(accountId: Data(hex: "0\(index)"), name: "Wallet", card: .wallet, extraData: .twin(TwinData(pairPublicKey: nil)), artwork: ArtworkInfo(id: "card_tg115", hash: "asd", date: "2022-01-01"), keys: [:])
    }
    static func noteBtc(index: Int) -> Account {
        return .init(accountId: Data(hex: "1\(index)"), name: "Note", card: .noteBtc, extraData: .twin(TwinData(pairPublicKey: nil)), artwork: ArtworkInfo(id: "card_tg109", hash: "asd", date: "2022-01-01"), keys: [:])
    }
    static func noteDoge(index: Int) -> Account {
        return .init(accountId: Data(hex: "2\(index)"), name: "Note", card: .noteDoge, extraData: .twin(TwinData(pairPublicKey: nil)), artwork: ArtworkInfo(id: "card_tg112", hash: "asd", date: "2022-01-01"), keys: [:])
    }
}

// MARK: -

class UserWalletListCellViewModel: ObservableObject, Identifiable {
    @Injected(\.cardImageLoader) var imageLoader: CardImageLoaderProtocol

    let account: Account
    let subtitle: String
    var cardImage: UIImage?

    private var bag: Set<AnyCancellable> = []

    init(account: Account, subtitle: String) {
        self.account = account
        self.subtitle = subtitle

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
    @Published var walletCellModels: [UserWalletListCellViewModel] = []
    @Published var noteCellModels: [UserWalletListCellViewModel] = []
    @Published var selectedAccountId: Data?

    // MARK: - Dependencies

    static var numberOfExtraWalletModels = 0

    private unowned let coordinator: UserWalletListRoutable

    init(
        coordinator: UserWalletListRoutable
    ) {
        self.coordinator = coordinator


        Self.numberOfExtraWalletModels = 2

        walletCellModels = [
            .init(account: .wallet(index: 0), subtitle: "3 Cards"),
        ]

//        let count = Int.random(in: 0 ... 2)


        for i in 0 ..< Self.numberOfExtraWalletModels {
            walletCellModels.append(
                .init(account: .wallet(index: i + 1), subtitle: "2 Cards")
            )
        }


        noteCellModels = [

        ]

        if Self.numberOfExtraWalletModels >= 1 {
            noteCellModels.append(.init(account: .noteBtc(index: 0), subtitle: "Bitcoin"))
        }

        if Self.numberOfExtraWalletModels >= 2 {
            noteCellModels.append(.init(account: .noteDoge(index: 0), subtitle: "Dogecoin"))
        }

        Self.numberOfExtraWalletModels += 1
        Self.numberOfExtraWalletModels = (Self.numberOfExtraWalletModels % 3)

        selectedAccountId = walletCellModels.first?.account.accountId
    }

    func onAccountTapped(_ account: Account) {
        self.selectedAccountId = account.accountId
    }
}
