//
//  ServicesAssembly+App.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemSdk

class AppServicesAssembly {
    weak var assembly: Assembly!
    lazy var navigationCoordinator = NavigationCoordinator()
    
    lazy var urlHandlers: [URLHandler] = [
        walletConnectService
    ]
    
    lazy var onboardingStepsSetupService: OnboardingStepsSetupService = {
        let service = OnboardingStepsSetupService()
        service.assembly = assembly
        service.backupService = backupService
        return service
    }()
    
  
    lazy var walletConnectService = WalletConnectService(assembly: assembly, cardScanner: walletConnectCardScanner, signer: signer, scannedCardsRepository: scannedCardsRepository)
    
    lazy var negativeFeedbackDataCollector: NegativeFeedbackDataCollector = {
        let collector = NegativeFeedbackDataCollector()
        collector.cardRepository = cardsRepository
        return collector
    }()
    
    lazy var twinsWalletCreationService = {
        TwinsWalletCreationService(tangemSdk: tangemSdk,
                                   twinFileEncoder: TwinCardTlvFileEncoder(),
                                   cardsRepository: cardsRepository,
                                   walletManagerFactory: WalletManagerFactory(config: keysManager.blockchainConfig))
    }()
    
    
    lazy var signer: TransactionSigner = {
        let signer = DefaultSigner(tangemSdk: self.tangemSdk,
                                   initialMessage: Message(header: nil,
                                                           body: "initial_message_sign_body".localized))
        signer.delegate = cardsRepository
        TestnetBuyCryptoService.signer = signer
        return signer
    }()
    
    lazy var walletConnectCardScanner: WalletConnectCardScanner = {
        let scanner = WalletConnectCardScanner()
        scanner.assembly = assembly
        scanner.tangemSdk = tangemSdk
        scanner.scannedCardsRepository = scannedCardsRepository
        scanner.tokenItemsRepository = tokenItemsRepository
        scanner.cardsRepository = cardsRepository
        return scanner
    }()
    
    lazy var shopifyService = ShopifyService(shop: keysManager.shopifyShop, testApplePayPayments: false)

    lazy var cardsRepository: CardsRepository = {
        let crepo = CardsRepository()
        crepo.tangemSdk = tangemSdk
        crepo.assembly = assembly
        crepo.delegate = self
        crepo.scannedCardsRepository = scannedCardsRepository
        crepo.tokenItemsRepository = tokenItemsRepository
        return crepo
    }()
   
    
    func onDidScan(_ cardInfo: CardInfo) {
        featuresService.setupFeatures(for: cardInfo.card)
//        warningsService.setupWarnings(for: cardInfo)

        if !featuresService.linkedTerminal {
            tangemSdk.config.linkedTerminal = false
        }
        
        if cardInfo.card.isTwinCard {
            tangemSdk.config.cardIdDisplayFormat = .last(4)
        }
        
        ratesService.card = cardInfo.card
        coinsService.card = cardInfo.card
    }
}

extension AppServicesAssembly: CardsRepositoryDelegate {
    func onWillScan() {
        tangemSdk.config = defaultSdkConfig
    }
}
