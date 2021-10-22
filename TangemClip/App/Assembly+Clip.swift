//
//  Assembly+Clip.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import Combine

extension Assembly {
    
    func getMainViewModel() -> MainViewModel {
        guard let model: MainViewModel = get() else {
            let mainModel = MainViewModel(cardsRepository: services.cardsRepository, imageLoaderService: services.imageLoaderService)
            store(mainModel, isResetable: true)
            return mainModel
        }
        
        return model
    }
    
    // MARK: Card model
    func makeCardModel(from info: CardInfo) -> CardViewModel {
        let vm = CardViewModel(cardInfo: info)
        vm.assembly = self
        vm.tangemSdk = services.tangemSdk
        vm.updateState()
        return vm
    }
    
    // MARK: Wallets
    func makeWalletModels(from info: CardInfo) -> AnyPublisher<[WalletModel], Never> {
        if info.isTangemNote {
            if let wallet = info.card.wallets.first,
               let blockchain = info.defaultBlockchain,
               let wm =  services.walletManagerFactory.makeWalletManager(from: info.card.cardId,
                                                                         wallet: wallet,
                                                                         blockchain: blockchain) {
                let model = WalletModel(cardWallet: wallet, walletManager: wm)
                model.ratesService = services.ratesService
                return Just([model]).eraseToAnyPublisher()
            } else {
                return Just([]).eraseToAnyPublisher()
            }
        } else {
            return info.card.wallets.publisher
                .removeDuplicates(by: { $0.curve == $1.curve })
                .compactMap { cardWallet -> [WalletModel]? in
                    let blockchains = SupportedBlockchains.blockchains(from: cardWallet.curve, testnet: false)
                    let managers = self.services.walletManagerFactory.makeWalletManagers(for: cardWallet, cardId: info.card.cardId, blockchains: blockchains)
                    
                    return managers.map {
                        let model = WalletModel(cardWallet: cardWallet, walletManager: $0)
                        model.ratesService = self.services.ratesService
                        return model
                    }
                }
                .reduce([], { $0 + $1 })
                .eraseToAnyPublisher()
        }
    }
    
    func updateAppClipCard(with batch: String?, fullLink: String) {
        let mainModel: MainViewModel? = get()
        mainModel?.updateCardBatch(batch, fullLink: fullLink)
    }
    
    
    private func get<T>(key: String) -> T? {
        let val = modelsStorage[key]
        return val as? T
    }
    
    private func get<T>() -> T? {
        let key = String(describing: type(of: T.self))
        return get(key: key)
    }
    
}
