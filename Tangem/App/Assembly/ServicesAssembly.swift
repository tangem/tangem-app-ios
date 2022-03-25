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
    
    lazy var keychain: KeychainSwift = {
        let keychain = KeychainSwift()
        keychain.synchronizable = true
        return keychain
    }()
    
    lazy var persistentStorage = PersistentStorage(encryptionUtility: fileEncriptionUtility)

    lazy var fileEncriptionUtility: FileEncryptionUtility = .init(keychain: keychain)

    lazy var userPrefsService = UserPrefsService()
    lazy var imageLoaderService: CardImageLoaderService = CardImageLoaderService()
   
    lazy var tangemSdk: TangemSdk = .init()
    
    lazy var scannedCardsRepository: ScannedCardsRepository = ScannedCardsRepository(storage: persistentStorage)
    
    lazy var defaultSdkConfig: Config = {
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
}
