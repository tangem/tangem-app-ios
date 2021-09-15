//
//  ServicesAssembly+App.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemSdk

class AppServicesAssembly: ServicesAssembly {
    lazy var urlHandlers: [URLHandler] = [
        walletConnectService
    ]
    
    lazy var onboardingStepsSetupService: OnboardingStepsSetupService = {
        let service = OnboardingStepsSetupService()
        service.userPrefs = userPrefsService
        service.assembly = assembly
        return service
    }()
    lazy var exchangeService: ExchangeService = MoonPayService(keys: keysManager.moonPayKeys)
    lazy var walletConnectService = WalletConnectService(assembly: assembly, cardScanner: walletConnectCardScanner, signer: signer, scannedCardsRepository: scannedCardsRepository)
    
    lazy var negativeFeedbackDataCollector: NegativeFeedbackDataCollector = {
        let collector = NegativeFeedbackDataCollector()
        collector.cardRepository = cardsRepository
        return collector
    }()
    
    lazy var failedCardScanTracker: FailedCardScanTracker = {
        let tracker = FailedCardScanTracker()
        tracker.logger = logger
        return tracker
    }()
    
    lazy var validatedCards = ValidatedCardsService(keychain: keychain)
    
    lazy var twinsWalletCreationService = {
        TwinsWalletCreationService(tangemSdk: tangemSdk,
                                   twinFileEncoder: TwinCardTlvFileEncoder(),
                                   cardsRepository: cardsRepository,
                                   walletManagerFactory: walletManagerFactory)
    }()
    
    
    lazy var signer: TransactionSigner = {
        let signer = DefaultSigner(tangemSdk: self.tangemSdk,
                                   initialMessage: Message(header: nil,
                                                           body: "initial_message_sign_header".localized))
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
    
    lazy var navigationCoordinator = NavigationCoordinator()
    lazy var featuresService = AppFeaturesService(configProvider: configManager)
    lazy var warningsService = WarningsService(remoteWarningProvider: configManager, rateAppChecker: rateAppService)
    lazy var rateAppService: RateAppService = .init(userPrefsService: userPrefsService)
    private let configManager = try! FeaturesConfigManager()
    
    override func onDidScan(_ cardInfo: CardInfo) {
        featuresService.setupFeatures(for: cardInfo.card)
//        warningsService.setupWarnings(for: cardInfo)
        tokenItemsRepository.setCard(cardInfo.card.cardId)
        
        if !featuresService.linkedTerminal {
            tangemSdk.config.linkedTerminal = false
        }
        
        if cardInfo.card.isTwinCard {
            tangemSdk.config.cardIdDisplayedNumbersCount = 4
        }
    }
}
