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

    var isMultiWallet: Bool {
        cardInfo.isMultiWallet
    }

    var isCardEmpty: Bool {
        cardInfo.card.wallets.isEmpty
    }

    @Published private(set) var walletModels: [WalletModel] = []

    private var erc20TokenWalletModel: WalletModel? {
        get {
            state.walletModels?.first(where: { $0.wallet.blockchain == .ethereum(testnet: true)
                                        || $0.wallet.blockchain == .ethereum(testnet: false)})
        }
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

    func updateState() {
        let models = assembly.makeWalletModels(from: cardInfo)
        self.state = models.isEmpty ? .empty : .loaded(walletModel: models)
        searchTokens()
        updateWallets()
    }

    func updateWallets() {
        state.walletModels?.forEach {
            updateWallet($0)
        }
    }

    private func updateWallet(_ walletModel: WalletModel) {
        guard let publisher: AnyPublisher<WalletModel, Error> = walletModel.update() else { return }
        var cancellable: AnyCancellable!
        cancellable = publisher
            .sink(receiveCompletion: { (completion) in
                self.bag.remove(cancellable)
            }, receiveValue: { (model) in
                if model.wallet.isEmpty || self.walletModels.contains(where: { $0 === model }) { return }

                withAnimation {
                    self.walletModels.append(model)
                }
            })
        bag.insert(cancellable)
    }

    private func searchTokens() {
        guard let ethWalletModel = erc20TokenWalletModel else { return }

        (ethWalletModel.walletManager as! TokenFinder).findErc20Tokens() { result in
            switch result {
            case .success(let isAdded):
                guard isAdded else { break }
                if !self.walletModels.contains(where: { $0 === ethWalletModel }) {
                    self.walletModels.append(ethWalletModel)
                }
            case .failure(let error):
                print(error)
            }
        }
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
