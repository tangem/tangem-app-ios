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

class AppServicesAssembly: ServicesAssembly {
    lazy var urlHandlers: [URLHandler] = [
        walletConnectService
    ]
    
    lazy var onboardingStepsSetupService: OnboardingStepsSetupService = {
        let service = OnboardingStepsSetupService()
        service.userPrefs = userPrefsService
        service.assembly = assembly
        service.backupService = backupService
        return service
    }()
    
    lazy var backupService: BackupService = {
        BackupService(sdk: tangemSdk)
    }()
    
    lazy var exchangeService: ExchangeService = CombinedExchangeService(
        buyService: OnramperService(key: keysManager.onramperApiKey),
        sellService: MoonPayService(keys: keysManager.moonPayKeys)
    )
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
    
    lazy var navigationCoordinator = NavigationCoordinator()
    lazy var featuresService = AppFeaturesService(configProvider: configManager)
    lazy var warningsService = WarningsService(remoteWarningProvider: configManager, rateAppChecker: rateAppService)
    lazy var rateAppService: RateAppService = .init(userPrefsService: userPrefsService)
    private let configManager = try! FeaturesConfigManager()
    lazy var shopifyService = ShopifyService(shop: keysManager.shopifyShop, testApplePayPayments: false)
    let keysManager = try! KeysManager()
    lazy var ratesService = CoinMarketCapService(apiKey: keysManager.coinMarketKey)
    lazy var tokenItemsRepository = TokenItemsRepository(persistanceStorage: persistentStorage)
    
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
    
    func onDidScan(_ cardInfo: CardInfo) {
        featuresService.setupFeatures(for: cardInfo.card)
//        warningsService.setupWarnings(for: cardInfo)

        if !featuresService.linkedTerminal {
            tangemSdk.config.linkedTerminal = false
        }
        
        if cardInfo.card.isTwinCard {
            tangemSdk.config.cardIdDisplayFormat = .last(4)
        }
    }
}

extension AppServicesAssembly: CardsRepositoryDelegate {
    func onWillScan() {
        tangemSdk.config = defaultSdkConfig
    }
}
