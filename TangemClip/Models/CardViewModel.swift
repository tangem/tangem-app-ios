//
//  Models.swift
//  TangemClip
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdkClips

class CardViewModel: ObservableObject {
    weak var tangemSdk: TangemSdk!
    weak var assembly: Assembly!
    
    @Published var state: State = .created
    
    @Published var cardInfo: CardInfo
    
    var isMultiWallet: Bool {
        cardInfo.card.isMultiWallet
    }
    
    var walletModels: [WalletModel] {
        state.walletModels ?? []
    }
    
    init(cardInfo: CardInfo) {
        self.cardInfo = cardInfo
    }
    
    func getCardInfo() {
        guard cardInfo.card.cardType == .release else {
            return
        }
        
        tangemSdk.getCardInfo(cardId: cardInfo.card.cardId ?? "", cardPublicKey: cardInfo.card.cardPublicKey ?? Data()) {[weak self] result in
            switch result {
            case .success(let info):
                guard let artwork = info.artwork else { return }

                self?.cardInfo.artworkInfo = artwork
            case .failure:
                print("Failed to validate card")
            }
        }
    }
    
    func updateState() {
        assembly.makeWalletModels(from: cardInfo)
            .map { $0.isEmpty ? State.empty : State.loaded(walletModel: $0) }
            .assign(to: &$state)
        update()
    }
    
    func update() {
        state.walletModels?.forEach { $0.update() }
    }
}

extension CardViewModel {
    enum State {
        case created
        case empty
        case loaded(walletModel: [WalletModel])
        
        var walletModels: [WalletModel]? {
            switch self {
            case .loaded(let models):
                return models
            default:
                return nil
            }
        }
        
        var canUpdate: Bool {
            switch self {
            case .loaded:
                return true
            default:
                return false
            }
        }
    }
}

extension CardViewModel {
    static var previewCardViewModel: CardViewModel {
        viewModel(for: Card.testCard)
    }
    
    private static func viewModel(for card: Card) -> CardViewModel {
        let assembly = Assembly.previewAssembly
        return assembly.services.cardsRepository.cards[card.cardId!]!.cardModel!
    }
}
