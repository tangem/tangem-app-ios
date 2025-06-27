//
//  CardInfo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk
import TangemHotSdk

struct WalletInfo {
    let name: String
    let type: WalletInfoType
}

enum WalletInfoType {
    case card(CardInfo)
    case hot(HotWalletInfo)
}

struct HotWalletInfo: Codable {
    let id: String
    let authType: AuthType?
    var wallets: [HotWallet]

    enum AuthType: String, Codable {
        case biometry
        case password

        init?(hotWalletAuthType: HotWalletID.AuthType?) {
            switch hotWalletAuthType {
            case .password:
                self = .password
            case .biometry:
                self = .biometry
            case .none:
                return nil
            }
        }

        var hotWalletAuthType: HotWalletID.AuthType {
            switch self {
            case .password: HotWalletID.AuthType.password
            case .biometry: HotWalletID.AuthType.biometry
            }
        }
    }

    init(hotWalletID: HotWalletID) {
        id = hotWalletID.value
        authType = AuthType(hotWalletAuthType: hotWalletID.authType)
        wallets = []
    }

    var hotWalletID: HotWalletID {
        return HotWalletID(
            value: id,
            authType: authType?.hotWalletAuthType
        )
    }
}

struct CardInfo {
    var card: CardDTO
    var walletData: DefaultWalletData
    var primaryCard: PrimaryCard?

    var cardIdFormatted: String {
        if case .twin(_, let twinData) = walletData {
            return AppTwinCardIdFormatter.format(cid: card.cardId, cardNumber: twinData.series.number)
        } else {
            return AppCardIdFormatter(cid: card.cardId).formatted()
        }
    }
}

extension HotWallet {
    var walletPublicInfo: WalletPublicInfo {
        WalletPublicInfo(
            publicKey: publicKey,
            chainCode: chainCode,
            curve: curve,
            isImported: false,
            derivedKeys: derivedKeys
        )
    }
}
