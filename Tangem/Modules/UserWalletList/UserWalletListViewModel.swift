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

struct UserWallet: Identifiable {
    var id = UUID()
    let userWalletId: Data
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

extension UserWallet {
    static func wallet(index: Int) -> UserWallet {
        .init(userWalletId: Data(hex: "0\(index)"), name: "Wallet", card: .wallet, extraData: .twin(TwinData(pairPublicKey: nil)), artwork: ArtworkInfo(id: "card_tg115", hash: "asd", date: "2022-01-01"), keys: [:])
    }
    static func noteBtc(index: Int) -> UserWallet {
        return .init(userWalletId: Data(hex: "1\(index)"), name: "Note", card: .noteBtc, extraData: .twin(TwinData(pairPublicKey: nil)), artwork: ArtworkInfo(id: "card_tg109", hash: "asd", date: "2022-01-01"), keys: [:])
    }
    static func noteDoge(index: Int) -> UserWallet {
        return .init(userWalletId: Data(hex: "2\(index)"), name: "Note", card: .noteDoge, extraData: .twin(TwinData(pairPublicKey: nil)), artwork: ArtworkInfo(id: "card_tg112", hash: "asd", date: "2022-01-01"), keys: [:])
    }
}

// MARK: -

// MARK: -

final class UserWalletListViewModel: ObservableObject {
    // MARK: - ViewState
    @Published var selectedUserWalletId: Data?
    @Published var multiCurrencyModels: [UserWalletListCellViewModel] = []
    @Published var singleCurrencyModels: [UserWalletListCellViewModel] = []


    // MARK: - Dependencies


    @Injected(\.cardsRepository) private var cardsRepository: CardsRepository

    static private var numberOfExtraWalletModels = 0

    private unowned let coordinator: UserWalletListRoutable

    private var bag: Set<AnyCancellable> = []

    init(
        coordinator: UserWalletListRoutable
    ) {
        self.coordinator = coordinator


        Self.numberOfExtraWalletModels = 2

        multiCurrencyModels = [
            .init(userWallet: .wallet(index: 0), subtitle: "3 Cards", numberOfTokens: Int.random(in: 5 ... 10)),
        ]

//        let count = Int.random(in: 0 ... 2)


        for i in 0 ..< Self.numberOfExtraWalletModels {
            multiCurrencyModels.append(
                .init(userWallet: .wallet(index: i + 1), subtitle: "2 Cards", numberOfTokens: Int.random(in: 5 ... 10))
            )
        }


        singleCurrencyModels = [

        ]

        if Self.numberOfExtraWalletModels >= 1 {
            singleCurrencyModels.append(.init(userWallet: .noteBtc(index: 0), subtitle: "Bitcoin", numberOfTokens: nil))
        }

        if Self.numberOfExtraWalletModels >= 2 {
            singleCurrencyModels.append(.init(userWallet: .noteDoge(index: 0), subtitle: "Dogecoin", numberOfTokens: nil))
        }

        Self.numberOfExtraWalletModels += 1
        Self.numberOfExtraWalletModels = (Self.numberOfExtraWalletModels % 3)

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
