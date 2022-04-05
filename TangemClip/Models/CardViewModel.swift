//
//  Models.swift
//  TangemClip
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import TangemSdk

class CardViewModel: ObservableObject {
    weak var tangemSdk: TangemSdk!
    weak var assembly: Assembly!

    @Published var state: State = .created

    @Published var cardInfo: CardInfo
    @Published var isLoadingArtwork: Bool = false
    @Published private(set) var loadingBalancesCounter: Int = 0 {
        didSet {
            print("Current loadingBalanceCounter value: \(loadingBalancesCounter)")
        }
    }

    var isCardEmpty: Bool {
        cardInfo.card.wallets.isEmpty
    }

    private var bag: Set<AnyCancellable> = [] {
        didSet {
            loadingBalancesCounter = bag.count
        }
    }

    init(cardInfo: CardInfo) {
        self.cardInfo = cardInfo
    }

    func getCardInfo() {
        guard cardInfo.card.firmwareVersion.type == .release else {
            cardInfo.artwork = .noArtwork
            return
        }

        tangemSdk.loadCardInfo(cardPublicKey: cardInfo.card.cardPublicKey, cardId: cardInfo.card.cardId) {[weak self] result in
            switch result {
            case .success(let info):
                guard let artwork = info.artwork else {
                    self?.cardInfo.artwork = .noArtwork
                    return
                }

                self?.cardInfo.artwork = .artwork(artwork)
            case .failure:
                self?.cardInfo.artwork = .noArtwork
                print("Failed to validate card")
            }
        }
    }
}

extension CardViewModel {
    enum State {
        case created
        case empty
    }
}

//extension CardViewModel {
//    static var previewCardViewModel: CardViewModel {
//        viewModel(for: Card.testCard)
//    }
//
//    private static func viewModel(for card: Card) -> CardViewModel {
//        let assembly = Assembly.previewAssembly
//        return assembly.services.cardsRepository.cards[card.cardId]!.cardModel!
//    }
//}
