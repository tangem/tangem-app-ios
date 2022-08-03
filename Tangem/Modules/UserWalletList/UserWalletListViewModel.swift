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
import enum TangemSdk.EllipticCurve
import Solana_Swift
import TangemSdk


// MARK: -

struct UserWallet: Identifiable {
    var id = UUID()
    let userWalletId: Data
    let name: String
    let card: Card
    let walletData: DefaultWalletData
    let artwork: ArtworkInfo?
    let keys: [Data: [DerivationPath: ExtendedPublicKey]] // encrypted
    let isHDWalletAllowed: Bool
}

enum DefaultWalletData {
    case note(WalletData)
    case v3(WalletData)
    case twin(TwinData)
    case none
}

struct TwinData {
    let cardId: String
    var pairPublicKey: Data?
}

extension UserWallet {
    static func wallet(index: Int) -> UserWallet {
        .init(userWalletId: Data(hex: "0\(index)"),
              name: "Wallet",
              card: .wallet,
              walletData: .twin(TwinData(cardId: "asdads", pairPublicKey: nil)),
              artwork: ArtworkInfo(id: "card_tg115",
                                   hash: "asd",
                                   date: "2022-01-01"),
              keys: [:],
              isHDWalletAllowed: true)
    }
    static func wallet2(index: Int) -> UserWallet {
        .init(userWalletId: Data(hex: "0\(index)"),
              name: "Wallet",
              card: .wallet2,
              walletData: .twin(TwinData(cardId: "asdads", pairPublicKey: nil)),
              artwork: ArtworkInfo(id: "card_tg115",
                                   hash: "asd",
                                   date: "2022-01-01"),
              keys: [:],
              isHDWalletAllowed: true)
    }

    static func walletTest(index: Int) -> UserWallet {
        .init(userWalletId: Data(hex: "0\(index)"),
              name: "Wallet",
              card: .walletTest,
              walletData: .twin(TwinData(cardId: "asdads", pairPublicKey: nil)),
              artwork: ArtworkInfo(id: "card_tg115",
                                   hash: "asd",
                                   date: "2022-01-01"),
              keys: [
                  Data(hex: "034c88a1a83469ddf20d0c07e5c4a1e7b83734e721e60d642b94a53222c47c670d"): [try! DerivationPath(rawPath: "m/44'/1'/0'/0/0"): ExtendedPublicKey(publicKey: Data(hex: "024a8ecfcdafc46de0edd3e39061613f14c0bf4fb0e2ddf8d9392c259ca36c3e16"), chainCode: Data(hex: "af63f9ce81b11c6fafb807c34e20144bb6ad64dd0cd9202768947a0f1b99cf02"))],
              ],
              isHDWalletAllowed: true)
    }

    static func noteBtc(index: Int) -> UserWallet {
        return .init(userWalletId: Data(hex: "1\(index)"),
                     name: "Note",
                     card: .noteBtc,
                     walletData: .note(.init(blockchain: "btc", token: nil)),
                     artwork: ArtworkInfo(id: "card_tg109",
                                          hash: "asd",
                                          date: "2022-01-01"),
                     keys: [:],
                     isHDWalletAllowed: true)
    }
    static func noteDoge(index: Int) -> UserWallet {
        return .init(userWalletId: Data(hex: "2\(index)"),
                     name: "Note",
                     card: .noteDoge,
                     walletData: .note(.init(blockchain: "doge", token: nil)),
                     artwork: ArtworkInfo(id: "card_tg112",
                                          hash: "asd",
                                          date: "2022-01-01"),
                     keys: [:],
                     isHDWalletAllowed: true)
    }

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

// MARK: -

final class UserWalletListViewModel: ObservableObject {
    // MARK: - ViewState
    @Published var selectedUserWalletId: Data?
    @Published var multiCurrencyModels: [CardViewModel] = []
    @Published var singleCurrencyModels: [CardViewModel] = []

    // MARK: - Dependencies


    @Injected(\.cardsRepository) private var cardsRepository: CardsRepository

    private unowned let coordinator: UserWalletListRoutable

    private var bag: Set<AnyCancellable> = []

    init(
        coordinator: UserWalletListRoutable
    ) {
        self.coordinator = coordinator

        multiCurrencyModels = [
            .init(cardInfo: UserWallet.wallet(index: 0).cardInfo(), savedCards: true),
            .init(cardInfo: UserWallet.wallet2(index: 1).cardInfo(), savedCards: true),
            .init(cardInfo: UserWallet.walletTest(index: 0).cardInfo(), savedCards: true),
        ]

        singleCurrencyModels = [
            .init(cardInfo: UserWallet.noteBtc(index: 0).cardInfo(), savedCards: true),
            .init(cardInfo: UserWallet.noteDoge(index: 0).cardInfo(), savedCards: true),
        ]

        selectedUserWalletId = multiCurrencyModels.first?.userWallet.userWalletId
    }

    func onUserWalletTapped(_ userWallet: UserWallet) {
        self.selectedUserWalletId = userWallet.userWalletId
    }

    func addCard() {
        cardsRepository.scanPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
//                if case let .failure(error) = completion {
//                    print("Failed to scan card: \(error)")
//                    self?.isScanningCard = false
//                    self?.failedCardScanTracker.recordFailure()

//                    if self?.failedCardScanTracker.shouldDisplayAlert ?? false {
//                        self?.showTroubleshootingView = true
//                    } else {
//                        switch error.toTangemSdkError() {
//                        case .unknownError, .cardVerificationFailed:
//                            self?.error = error.alertBinder
//                        default:
//                            break
//                        }
//                    }
//                }
//                subscription.map { _ = self?.bag.remove($0) }
            } receiveValue: { [weak self] cardModel in
//                self?.failedCardScanTracker.resetCounter()
                self?.processScannedCard(cardModel)
            }
            .store(in: &bag)
    }

    private func processScannedCard(_ cardModel: CardViewModel) {
        print(cardModel)
    }
}
