//
//  UserWallet.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct UserWallet: Identifiable, Codable {
    var id = UUID()
    let userWalletId: Data
    let name: String
    let card: Card
    let walletData: DefaultWalletData
    let artwork: ArtworkInfo?
    let keys: [Data: [DerivationPath: ExtendedPublicKey]] // encrypted
    let isHDWalletAllowed: Bool
}

enum DefaultWalletData: Codable {
    case note(WalletData)
    case v3(WalletData)
    case twin(TwinData)
    case none
}

struct TwinData: Codable {
    let cardId: String
    var pairPublicKey: Data?
}

extension UserWallet {
//    static func wallet(index: Int) -> UserWallet {
//        .init(userWalletId: Data(hexString: "0\(index)"),
//              name: "Wallet",
//              card: .wallet,
//              walletData: .twin(TwinData(cardId: "asdads", pairPublicKey: nil)),
//              artwork: ArtworkInfo(id: "card_tg115",
//                                   hash: "asd",
//                                   date: "2022-01-01"),
//              keys:
//              [
//                  Data(hexString: "027d5a2f0c54270b60163e837011fda89da3dc03127d4545f50cd3fe4df7e6895b"): [
//
//                      try! DerivationPath(rawPath: "m/44'/60'/0'/0/0"):
//                          ExtendedPublicKey(
//                              publicKey: Data(hexString: "0380cfac2cb7280925a5962a6f62c19bee2da10aa9f084132f78fca7f92d71ccee"),
//                              chainCode: Data(hexString: "ac322e35219bf023c18cd7761dea87bf234981d6da6b13b649e147618962ebaa")
//                          ),
//
//                      try! DerivationPath(rawPath: "m/44'/3'/0'/0/0"):
//                          ExtendedPublicKey(
//                              publicKey: Data(hexString: "02500b929f65d59eb2e4883b532b1a8c4ebec213804e04cc0172ea8fd6d1be8aaa"),
//                              chainCode: Data(hexString: "eb732996b5d5627faa831c14e3f65ac6c8c4e872a2c519e719f5e0f05df7a071")
//                          ),
//
//                      try! DerivationPath(rawPath: "m/44'/9006'/0'/0/0"):
//                          ExtendedPublicKey(
//                              publicKey: Data(hexString: "025f81e5e1ebc79447bd11358a926ce3d2d7cbfd9ecb2e22834f769fc29dd54ec2"),
//                              chainCode: Data(hexString: "c3d1aaac7359df018562f937d259d6e6927d5a2f39ee5b83b1a0c39b9e411f96")
//                          ),
//
//                      try! DerivationPath(rawPath: "m/44'/9001'/0'/0/0"):
//                          ExtendedPublicKey(
//                              publicKey: Data(hexString: "03b6253bd4f105f56dcff8fd285c605731a2d09d2f57ec2d79702cb3ead4f07d38"),
//                              chainCode: Data(hexString: "c65c4e5ca22ba82db9caa3b3ccf5c7c956debc55f310156b16c97251e4e67cfe")
//                          ),
//
//                      try! DerivationPath(rawPath: "m/44'/700'/0'/0/0"):
//                          ExtendedPublicKey(
//                              publicKey: Data(hexString: "02cdfd5456348151110d500ec5f42127c2ea16a3fecdff4007db65c8c8e5b887a9"),
//                              chainCode: Data(hexString: "c8dfdee25d1438e8c931a805bf2d9c69279df1fcc9832301227feff1ad819a59")
//                          ),
//
//                      try! DerivationPath(rawPath: "m/44'/501'/0'"):
//                          ExtendedPublicKey(
//                              publicKey: Data(hexString: "043bd15297f0ca2350af0bec584614cd842d7349b1f5088b52835bc86cd13ae7"),
//                              chainCode: Data(hexString: "329646e32dc0ba9830229d3b2a74bcbb3cd6bba59f186cdff92c303e3f0e7f0e")
//                          ),
//
//                  ],
//
//
//              ],
//
//
//
//              isHDWalletAllowed: true)
//    }
//    static func wallet2(index: Int) -> UserWallet {
//        .init(userWalletId: Data(hexString: "0\(index)"),
//              name: "Wallet",
//              card: .wallet2,
//              walletData: .twin(TwinData(cardId: "asdads", pairPublicKey: nil)),
//              artwork: ArtworkInfo(id: "card_tg115",
//                                   hash: "asd",
//                                   date: "2022-01-01"),
//              keys: [:],
//              isHDWalletAllowed: true)
//    }
//
//    static func walletTest(index: Int) -> UserWallet {
//        .init(userWalletId: Data(hexString: "0\(index)"),
//              name: "Wallet",
//              card: .walletTest,
//              walletData: .twin(TwinData(cardId: "asdads", pairPublicKey: nil)),
//              artwork: ArtworkInfo(id: "card_tg115",
//                                   hash: "asd",
//                                   date: "2022-01-01"),
//              keys: [
//                  Data(hexString: "034c88a1a83469ddf20d0c07e5c4a1e7b83734e721e60d642b94a53222c47c670d"): [try! DerivationPath(rawPath: "m/44'/1'/0'/0/0"): ExtendedPublicKey(publicKey: Data(hexString: "024a8ecfcdafc46de0edd3e39061613f14c0bf4fb0e2ddf8d9392c259ca36c3e16"), chainCode: Data(hexString: "af63f9ce81b11c6fafb807c34e20144bb6ad64dd0cd9202768947a0f1b99cf02"))],
//              ],
//              isHDWalletAllowed: true)
//    }
//
//    static func noteBtc(index: Int) -> UserWallet {
//        return .init(userWalletId: Data(hexString: "1\(index)"),
//                     name: "Note",
//                     card: .noteBtc,
//                     walletData: .note(.init(blockchain: "btc", token: nil)),
//                     artwork: ArtworkInfo(id: "card_tg109",
//                                          hash: "asd",
//                                          date: "2022-01-01"),
//                     keys: [:],
//                     isHDWalletAllowed: false)
//    }
//    static func noteDoge(index: Int) -> UserWallet {
//        return .init(userWalletId: Data(hexString: "2\(index)"),
//                     name: "Note",
//                     card: .noteDoge,
//                     walletData: .note(.init(blockchain: "doge", token: nil)),
//                     artwork: ArtworkInfo(id: "card_tg112",
//                                          hash: "asd",
//                                          date: "2022-01-01"),
//                     keys: [:],
//                     isHDWalletAllowed: false)
//    }

    func cardInfo() -> CardInfo {
        let cardInfoWalletData: WalletData?
        if case let .note(wd) = walletData {
            cardInfoWalletData = wd
        } else {
            cardInfoWalletData = nil
        }
        return CardInfo(
            card: card,
            name: self.name,
            walletData: cardInfoWalletData,
            artwork: artwork == nil ? .noArtwork : .artwork(artwork!),
            twinCardInfo: nil,
            isTangemNote: isTangemNote,
            isTangemWallet: isTangemWallet,
            derivedKeys: keys,
            primaryCard: nil
        )
    }
}

extension UserWallet {
    var isTangemNote: Bool {
        return card.cardId == Card.noteBtc.cardId || card.cardId == Card.noteDoge.cardId
    }

    var isTangemWallet: Bool {
        !isTangemNote
    }
}
