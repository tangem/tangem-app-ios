//
//  ServicesAssembly.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
#if !CLIP
import BlockchainSdk
#endif
import KeychainSwift

class ServicesAssembly {
    weak var assembly: Assembly!
  
    deinit {
        print("ServicesAssembly deinit")
    }
    
    let logger = Logger()
    let keysManager = try! KeysManager()
    
    lazy var keychain: KeychainSwift = {
        let keychain = KeychainSwift()
        keychain.synchronizable = true
        return keychain
    }()
    
    lazy var persistentStorage = PersistentStorage(encryptionUtility: fileEncriptionUtility)
    lazy var tokenItemsRepository = TokenItemsRepository(persistanceStorage: persistentStorage)

    lazy var fileEncriptionUtility: FileEncryptionUtility = .init(keychain: keychain)

    lazy var ratesService = CoinMarketCapService(apiKey: keysManager.coinMarketKey)
    lazy var userPrefsService = UserPrefsService()
    lazy var imageLoaderService: CardImageLoaderService = CardImageLoaderService()
   
    lazy var tangemSdk: TangemSdk = .init()
    
    lazy var scannedCardsRepository: ScannedCardsRepository = ScannedCardsRepository(storage: persistentStorage)
    lazy var cardsRepository: CardsRepository = {
        let crepo = CardsRepository()
        crepo.tangemSdk = tangemSdk
        crepo.assembly = assembly
        crepo.delegate = self
        crepo.scannedCardsRepository = scannedCardsRepository
        crepo.tokenItemsRepository = tokenItemsRepository
        crepo.userPrefsService = userPrefsService
        return crepo
    }()
    
    private lazy var defaultSdkConfig: Config = {
        var config = Config()
        config.filter.allowedCardTypes = [.release, .sdk]
        config.logConfig = Log.Config.custom(logLevel: Log.Level.allCases, loggers: [logger, ConsoleLogger()])
        config.filter.batchIdFilter = .deny(["0027", //todo: tangem tags
                                             "0030",
                                             "0031",
                                             "0035"])
        
        config.filter.issuerFilter = .deny(["TTM BANK"])
        config.allowUntrustedCards = true
        return config
    }()
    
    func onDidScan(_ cardInfo: CardInfo) {
    } 
}

extension ServicesAssembly: CardsRepositoryDelegate {
    func onWillScan() {
        tangemSdk.config = defaultSdkConfig
    }
}
