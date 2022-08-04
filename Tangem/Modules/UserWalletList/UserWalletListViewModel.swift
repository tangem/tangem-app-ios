//
//  UserWalletListViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

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

        let userWallets = savedUserWallets()
        let singleCurrencyWallets = userWallets.filter {
            if case .note = $0.walletData {
                return true
            } else {
                return false
            }
        }
        let multiCurrencyWallets = userWallets.filter {
            if case .note = $0.walletData {
                return false
            } else {
                return true
            }
        }

        multiCurrencyModels = multiCurrencyWallets.map { .init(cardInfo: $0.cardInfo(), savedCards: true) }
        singleCurrencyModels = singleCurrencyWallets.map { .init(cardInfo: $0.cardInfo(), savedCards: true) }
        selectedUserWalletId = userWallets.first?.userWalletId
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
        let cardInfo = cardModel.cardInfo
        let card = cardInfo.card

        let walletData: DefaultWalletData

        if let cardInfoWalletData = cardInfo.walletData {
            walletData = .note(cardInfoWalletData)
        } else {
            walletData = .none
        }
        // [REDACTED_TODO_COMMENT]

        let name: String
        switch walletData {
        case .note:
            name = "Note"
        case .v3:
            name = "Wallet"
        case .twin:
            name = "Twin"
        case .none:
            name = "Wallet"
        }

        let userWallet = UserWallet(userWalletId: card.cardPublicKey, name: name, card: card, walletData: walletData, artwork: nil, keys: cardInfo.derivedKeys, isHDWalletAllowed: card.settings.isHDWalletAllowed)

        var userWallets = savedUserWallets()

        guard !userWallets.contains(where: { $0.userWalletId == userWallet.userWalletId }) else {
            return
        }

        userWallets.append(userWallet)
        singleCurrencyModels.append(.init(cardInfo: userWallet.cardInfo(), savedCards: true))

        saveUserWallets(userWallets)
    }

    private func savedUserWallets() -> [UserWallet] {
        do {
            let data = AppSettings.shared.userWallets
            return try JSONDecoder().decode([UserWallet].self, from: data)
        } catch {
            print(error)
            return []
        }
    }

    private func saveUserWallets(_ userWallets: [UserWallet]) {
        do {
            let data = try JSONEncoder().encode(userWallets)
            AppSettings.shared.userWallets = data
        } catch {
            print(error)
        }
    }
}
