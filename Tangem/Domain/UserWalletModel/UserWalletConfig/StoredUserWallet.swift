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
    var walletInfo: WalletInfo
}

extension StoredUserWallet {
    enum SensitiveInfo {
        case cardWallet(keys: [CardDTO.Wallet])
        case mobileWallet(keys: [KeyInfo])

        var asWalletKeys: WalletKeys {
            switch self {
            case .cardWallet(let keys):
                return .cardWallet(keys: keys)
            case .mobileWallet(let keys):
                return .mobileWallet(keys: keys)
            }
        }

        func serialize(encoder: JSONEncoder) throws -> Data {
            switch self {
            case .cardWallet(let keys):
                let serialized = StoredUserWallet.SensitiveInfo.StoredDTO(wallets: keys)
                let encoded = try encoder.encode(serialized)
                return encoded
            case .mobileWallet(let keys):
                let serialized = StoredUserWallet.SensitiveInfo.StoredDTO(wallets: keys)
                let encoded = try encoder.encode(serialized)
                return encoded
            }
        }

        static func deserialize(from decodable: Data, decoder: JSONDecoder) -> Self? {
            if let cardWalletData = try? decoder.decode(
                StoredUserWallet.SensitiveInfo.StoredDTO<CardDTO.Wallet>.self,
                from: decodable
            ) {
                return .cardWallet(keys: cardWalletData.wallets)
            }

            if let mobileWalletData = try? decoder.decode(
                StoredUserWallet.SensitiveInfo.StoredDTO<KeyInfo>.self,
                from: decodable
            ) {
                return .mobileWallet(keys: mobileWalletData.wallets)
            }

            return nil
        }
    }
}

extension StoredUserWallet.SensitiveInfo {
    struct StoredDTO<T: Codable>: Codable {
        let wallets: [T]
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
        case hotWalletInfo
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userWalletId = try container.decode(Data.self, forKey: .userWalletId)
        name = try container.decode(String.self, forKey: .name)

        if let hotWallet = try? container.decode(HotWalletInfo.self, forKey: .hotWalletInfo) {
            walletInfo = .mobileWallet(hotWallet)
        } else if let cardDTOv4 = try? container.decode(CardDTOv4.self, forKey: .card) {
            let associatedCardIds = try container.decode(Set<String>.self, forKey: .associatedCardIds)
            let walletData = try container.decode(DefaultWalletData.self, forKey: .walletData)

            let cardDTO = CardDTO(cardDTOv4: cardDTOv4)
            let cardInfo = CardInfo(
                card: cardDTO,
                walletData: walletData,
                associatedCardIds: associatedCardIds
            )
            walletInfo = WalletInfo.cardWallet(cardInfo)
        } else {
            let cardDTO = try container.decode(CardDTO.self, forKey: .card)
            let associatedCardIds = try container.decode(Set<String>.self, forKey: .associatedCardIds)
            let walletData = try container.decode(DefaultWalletData.self, forKey: .walletData)

            let cardInfo = CardInfo(
                card: cardDTO,
                walletData: walletData,
                associatedCardIds: associatedCardIds
            )

            walletInfo = WalletInfo.cardWallet(cardInfo)
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userWalletId, forKey: .userWalletId)
        try container.encode(name, forKey: .name)

        switch walletInfo {
        case .cardWallet(let cardInfo):
            try container.encode(cardInfo.walletData, forKey: .walletData)
            try container.encode(cardInfo.associatedCardIds, forKey: .associatedCardIds)
            try container.encode(cardInfo.card, forKey: .card)
        case .mobileWallet(let hotWalletInfo):
            try container.encode(hotWalletInfo, forKey: .hotWalletInfo)
        }
    }
}
