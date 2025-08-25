//
//  CardMock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemAccessibilityIdentifiers

enum CardMock: String, CaseIterable {
    case wallet2
    case wallet
    case twin
    case xrpNote
    case xlmBird
    case visa
    case visaTestnet
    case wallet2Demo
    case walletDemo
    case ethNoteDemo

    var accessibilityIdentifier: String {
        switch self {
        case .wallet2:
            return CardMockAccessibilityIdentifiers.wallet2.rawValue
        case .wallet:
            return CardMockAccessibilityIdentifiers.wallet.rawValue
        case .twin:
            return CardMockAccessibilityIdentifiers.twin.rawValue
        case .xrpNote:
            return CardMockAccessibilityIdentifiers.xrpNote.rawValue
        case .xlmBird:
            return CardMockAccessibilityIdentifiers.xlmBird.rawValue
        case .visa:
            return CardMockAccessibilityIdentifiers.visa.rawValue
        case .visaTestnet:
            return CardMockAccessibilityIdentifiers.visaTestNet.rawValue
        case .wallet2Demo:
            return CardMockAccessibilityIdentifiers.wallet2Demo.rawValue
        case .walletDemo:
            return CardMockAccessibilityIdentifiers.walletDemo.rawValue
        case .ethNoteDemo:
            return CardMockAccessibilityIdentifiers.ethNoteDemo.rawValue
        }
    }

    var cardInfo: CardInfo {
        .init(card: CardDTO(card: card), walletData: walletData, associatedCardIds: [])
    }

    var card: Card {
        decodeFromURL(url)!
    }

    var name: String { rawValue }

    var walletData: DefaultWalletData {
        switch self {
        case .twin:
            return .twin(
                WalletData(blockchain: "BTC", token: nil),
                TwinData(series: .cb61, pairPublicKey: Data(hexString: "0417553CDACA4928E934C4DCC519697634A283163C63BE5BA3EF6D1F8A7D987AE0E1DA3B8E04505C3356AA3669EB271FC344F93E1C541D5DD425726A06183C6DB4"))
            )
        case .visa:
            return .none
        case .visaTestnet:
            return .none
        case .wallet2:
            return .none
        case .wallet:
            return .none
        case .xlmBird:
            return .legacy(WalletData(blockchain: "XLM", token: nil))
        case .xrpNote:
            return .file(WalletData(blockchain: "XRP", token: nil))
        case .wallet2Demo:
            return .none
        case .walletDemo:
            return .none
        case .ethNoteDemo:
            return .file(WalletData(blockchain: "ETH", token: nil))
        }
    }

    private var url: URL {
        switch self {
        case .twin:
            return url(fileName: "twinCard")
        case .visa:
            return url(fileName: "visa")
        case .visaTestnet:
            return url(fileName: "visaTestnet")
        case .wallet2:
            return url(fileName: "wallet2")
        case .wallet:
            return url(fileName: "wallet")
        case .xlmBird:
            return url(fileName: "xlmBird")
        case .xrpNote:
            return url(fileName: "xrpNote")
        case .wallet2Demo:
            return url(fileName: "wallet2Demo")
        case .walletDemo:
            return url(fileName: "walletDemo")
        case .ethNoteDemo:
            return url(fileName: "ethNoteDemo")
        }
    }

    private func url(fileName: String) -> URL {
        Bundle.main.url(forResource: fileName, withExtension: "json")!
    }

    private func decodeFromURL(_ url: URL) -> Card? {
        AppLogger.info("Attempt to decode file at url: \(url)")
        let dataStr = try! String(contentsOf: url)
        let decoder = JSONDecoder.tangemSdkDecoder
        decoder.keyDecodingStrategy = .useDefaultKeys
        do {
            AppLogger.info(dataStr)
            return try decoder.decode(Card.self, from: dataStr.data(using: .utf8)!)
        } catch {
            AppLogger.error("Failed to decode card", error: error)
        }
        return nil
    }
}
