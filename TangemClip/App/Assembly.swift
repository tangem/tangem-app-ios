//
//  Assembly.swift
//  TangemClip
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdkClips

class Assembly {
    
    lazy var networkService = NetworkService()
    lazy var imageLoaderService = ImageLoaderService(networkService: networkService)
    
    lazy var tangemSdk: TangemSdk = {
       let sdk = TangemSdk()
        sdk.config = Config()
        return sdk
    }()
    lazy var cardsRepository: CardsRepository = {
        let repo = CardsRepository()
        repo.tangemSdk = tangemSdk
        repo.assembly = self
        return repo
    }()
    
    private var modelsStorage = [String : Any]()
    
    var sdkConfig: Config {
        Config()
    }
    
    func getMainViewModel() -> MainViewModel {
        guard let model: MainViewModel = get() else {
            let mainModel = MainViewModel(cardsRepository: cardsRepository, imageLoaderService: imageLoaderService)
            store(mainModel)
            return mainModel
        }
        
        return model
    }
    
    func getCardModel(from info: CardInfo) -> CardViewModel? {
        guard let model: CardViewModel = get() else {
            let cardViewModel = CardViewModel(cardInfo: info)
            store(cardViewModel)
            return cardViewModel
        }
        
        model.cardInfo = info
        return model
    }
    
    func updateAppClipCard(with batch: String?) {
        let mainModel: MainViewModel? = get()
        mainModel?.updateCardBatch(batch)
    }
    
    func updateCardUrl(_ url: String) {
        let mainModel: MainViewModel? = get()
        mainModel?.cardUrl = url
    }
    
    private func store<T>(_ object: T ) {
        let key = String(describing: type(of: T.self))
        store(object, with: key)
    }
    
    private func store<T>(_ object: T, with key: String) {
        //print(key)
        modelsStorage[key] = object
    }
    
    private func get<T>() -> T? {
        let key = String(describing: type(of: T.self))
        return get(key: key)
    }
    
    private func get<T>(key: String) -> T? {
        modelsStorage[key] as? T
    }
}

extension Assembly {
    static var previewAssembly: Assembly = {
        let assembly = Assembly()
        
        // Bitcoin old test card
        let testCardScan = scanResult(for: Card.testCard, assembly: assembly)
        
        // Which card data should be displayed in preview?
        assembly.cardsRepository.lastScanResult = testCardScan
        return assembly
    }()
    
    private static func scanResult(for card: Card, assembly: Assembly, twinCardInfo: TwinCardInfo? = nil) -> ScanResult {
        let ci = CardInfo(card: card,
                          artworkInfo: nil,
                          twinCardInfo: twinCardInfo)
        let vm = assembly.getCardModel(from: ci)!
        let scanResult = ScanResult.card(model: vm)
        assembly.cardsRepository.cards[card.cardId!] = scanResult
        return scanResult
    }
}
