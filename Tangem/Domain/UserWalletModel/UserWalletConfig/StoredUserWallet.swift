//
//  StoredUserWallet.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import TangemSdk
import TangemHotSdk

struct StoredUserWallet: Identifiable, Encodable {
    var id = UUID()
    let userWalletId: Data
    var name: String
    var walletInfo: StoredWalletInfo
    var associatedCardIds: Set<String>
    let walletData: DefaultWalletData

    func resettingWallets() -> Self {
        StoredUserWallet(
            id: id,
            userWalletId: userWalletId,
            name: name,
            walletInfo: walletInfo.resettingWallets(),
            associatedCardIds: associatedCardIds,
            walletData: walletData
        )
    }
}

enum StoredWalletInfo: Codable {
    case card(CardDTO)
    case hotWallet(HotWalletInfo)

    var isLocked: Bool {
        switch self {
        case .card(let cardDTO):
            return cardDTO.wallets.isEmpty
        case .hotWallet(let hotWallet):
            return hotWallet.wallets.isEmpty
        }
    }

    func resettingWallets() -> Self {
        switch self {
        case .card(let cardDTO):
            var card = cardDTO
            card.wallets = []
            return .card(card)
        case .hotWallet(let hotWalletInfo):
            var hotWallet = hotWalletInfo
            hotWallet.wallets = []
            return .hotWallet(hotWallet)
        }
    }

    var wallets: [WalletPublicInfo] {
        switch self {
        case .card(let card):
            card.wallets.map(\.walletPublicInfo)
        case .hotWallet(let hotWallet):
            hotWallet.wallets.map(\.walletPublicInfo)
        }
    }
}

extension StoredUserWallet {
    struct SensitiveInformation<T: Codable>: Codable {
        let wallets: [T]
    }
}

extension StoredUserWallet {
    var isLocked: Bool {
        walletInfo.isLocked
    }

    var cardInfo: CardInfo? {
        switch walletInfo {
        case .card(let card):
            CardInfo(
                card: card,
                walletData: walletData,
                primaryCard: nil
            )
        case .hotWallet: nil
        }
    }

    var info: WalletInfo {
        let walletInfoType: WalletInfoType
        switch walletInfo {
        case .card(let card):
            walletInfoType = .card(
                CardInfo(
                    card: card,
                    walletData: walletData,
                    primaryCard: nil
                ))
        case .hotWallet(let hotWallet):
            walletInfoType = .hot(hotWallet)
        }

        return WalletInfo(name: name, type: walletInfoType)
    }
}

extension StoredUserWallet: Decodable {
    enum CodingKeys: String, CodingKey {
        case id
        case userWalletId
        case name
        case associatedCardIds
        case walletData
        case card
        case cardDTOv4
        case walletInfo
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userWalletId = try container.decode(Data.self, forKey: .userWalletId)
        name = try container.decode(String.self, forKey: .name)
        associatedCardIds = try container.decode(Set<String>.self, forKey: .associatedCardIds)
        walletData = try container.decode(DefaultWalletData.self, forKey: .walletData)

        if let hotWallet = try? container.decode(HotWalletInfo.self, forKey: .walletInfo) {
            walletInfo = .hotWallet(hotWallet)
        } else if let cardDTOv4 = try? container.decode(CardDTOv4.self, forKey: .card) {
            walletInfo = .card(.init(cardDTOv4: cardDTOv4))
        } else {
            walletInfo = .card(try container.decode(CardDTO.self, forKey: .card))
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userWalletId, forKey: .userWalletId)
        try container.encode(name, forKey: .name)
        try container.encode(associatedCardIds, forKey: .associatedCardIds)
        try container.encode(walletData, forKey: .walletData)

        switch walletInfo {
        case .card(let card):
            try container.encode(card, forKey: .card)
        case .hotWallet(let hotWallet):
            try container.encode(hotWallet, forKey: .walletInfo)
        }
    }
}

protocol NameableWallet {
    var name: String { get set }
}

extension StoredUserWallet: NameableWallet {}
