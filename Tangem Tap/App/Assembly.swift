//
//  Assembly.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

class Assembly {
	let keysManager = try! KeysManager()
    let configManager = try! FeaturesConfigManager()
    let logger = Logger()
    
    lazy var tangemSdk: TangemSdk = {
        let sdk = TangemSdk()
        return sdk
    }()
    
    lazy var sdkConfig: Config = {
        var config = Config()
        config.logСonfig = Log.Config.custom(logLevel: Log.Level.allCases, loggers: [logger])
        return config
    }()
    
    lazy var navigationCoordinator = NavigationCoordinator()
	lazy var ratesService = CoinMarketCapService(apiKey: keysManager.coinMarketKey)
    lazy var userPrefsService = UserPrefsService()
    lazy var networkService = NetworkService()
	lazy var walletManagerFactory = WalletManagerFactory(config: keysManager.blockchainConfig)
    lazy var featuresService = AppFeaturesService(configProvider: configManager)
    lazy var warningsService = WarningsService(remoteWarningProvider: configManager, rateAppChecker: rateAppService)
    lazy var persistentStorage = PersistentStorage()
    lazy var walletItemsRepository = WalletItemsRepository(persistanceStorage: persistentStorage)
    lazy var keychainService = ValidatedCardsService()
    lazy var imageLoaderService: ImageLoaderService = {
        return ImageLoaderService(networkService: networkService)
    }()
    lazy var topupService: TopupService = {
		let s = TopupService(keys: keysManager.moonPayKeys)
        return s
    }()
    lazy var rateAppService: RateAppService = RateAppService(userPrefsService: userPrefsService)
    
    lazy var cardsRepository: CardsRepository = {
        let crepo = CardsRepository(twinCardFileDecoder: TwinCardTlvFileDecoder(), cardValidator: keychainService)
        crepo.tangemSdk = tangemSdk
        crepo.assembly = self
        crepo.onScan = onScan
        return crepo
    }()
	
	lazy var twinsWalletCreationService = {
		TwinsWalletCreationService(tangemSdk: tangemSdk,
								   twinFileEncoder: TwinCardTlvFileEncoder(),
                                   cardsRepository: cardsRepository,
                                   validatedCardsService: keychainService)
	}()
    
    private var modelsStorage = [String : Any]()
    
    func makeReadViewModel() -> ReadViewModel {
        if let restored: ReadViewModel = get() {
            return restored
        }
        
        let vm =  ReadViewModel(failedCardScanTracker: FailedCardScanTracker(logger: logger))
        initialize(vm)
        vm.userPrefsService = userPrefsService
        vm.cardsRepository = cardsRepository
        return vm
    }
    
    // MARK: Main view model
    func makeMainViewModel() -> MainViewModel {
        if let restored: MainViewModel = get() {
            let restoredCid = restored.state.card?.cardId ?? ""
            let newCid = cardsRepository.lastScanResult.card?.cardId ?? ""
            if restoredCid != newCid {
                restored.state = cardsRepository.lastScanResult
            }
            return restored
        }
        let vm =  MainViewModel()
        initialize(vm)
        vm.cardsRepository = cardsRepository
        vm.imageLoaderService = imageLoaderService
        vm.topupService = topupService
		vm.userPrefsService = userPrefsService
        vm.warningsManager = warningsService
        vm.state = cardsRepository.lastScanResult
        vm.rateAppController = rateAppService
        
        vm.negativeFeedbackDataCollector = NegativeFeedbackDataCollector(cardRepository: cardsRepository)
        vm.failedCardScanTracker = FailedCardScanTracker(logger: logger)
        
        return vm
    }
    
    func makeTokenDetailsViewModel(with card: CardViewModel, blockchain: Blockchain, amountType: Amount.AmountType = .coin) -> TokenDetailsViewModel {
        let vm =  TokenDetailsViewModel(blockchain: blockchain, amountType: amountType)
        initialize(vm)
        vm.card = card
        vm.topupService = topupService
        return vm
    }
    
    func makeWalletModels(from cardInfo: CardInfo, blockchains: [Blockchain], tokens: [Token]) -> [WalletModel]? {
        guard let walletPublicKey = cardInfo.card.walletPublicKey,
              let cardId = cardInfo.card.cardId else {
            return nil
        }
        
        let walletManagers = blockchains.map { walletManagerFactory.makeWalletManager(from: $0,
                                                                                      walletPublicKey: walletPublicKey,
                                                                                      cardId: cardId,
                                                                                      walletPairPublicKey: nil,
                                                                                      tokens: tokens,
                                                                                      canManageTokens: true)}
        
        let models = walletManagers.map { WalletModel(walletManager: $0,
                                                      ratesService: ratesService,
                                                      walletItemsRepository: walletItemsRepository)}
        return models
    }
    
    func makeWalletModel(from cardInfo: CardInfo) -> [WalletModel]? {
		let card = cardInfo.card
		var pairKey: Data? = nil
		if card.isTwinCard {
			guard let savedPairKey = cardInfo.twinCardInfo?.pairPublicKey else {
				return nil
			}
			
			pairKey = savedPairKey
		}
		
        let savedBlockchains = walletItemsRepository.walletItems.compactMap { $0.blockchain }
        let savedTokens = walletItemsRepository.walletItems.compactMap { $0.token }
        
        if cardInfo.isMultiWallet && savedBlockchains.count > 0 {
            return makeWalletModels(from: cardInfo, blockchains: savedBlockchains, tokens: savedTokens)
        } else {
            guard let walletManager = walletManagerFactory.makeWalletManager(from: card,
                                                                             tokens: savedTokens,
                                                                             pairKey: pairKey) else {
                return nil
            }
            
            if cardInfo.isMultiWallet {
                walletItemsRepository.append(.blockchain(walletManager.wallet.blockchain))
            }
            
            return [WalletModel(walletManager: walletManager,
                               ratesService: ratesService,
                               walletItemsRepository: walletItemsRepository)]
        }
    }
    
    // MARK: Card model
    func makeCardModel(from info: CardInfo) -> CardViewModel? {
        guard let blockchainName = info.card.cardData?.blockchainName,
              let curve = info.card.curve,
              let blockchain = Blockchain.from(blockchainName: blockchainName, curve: curve) else {
            return nil
        }
        
        let vm = CardViewModel(cardInfo: info)
        vm.featuresService = featuresService
        vm.assembly = self
        vm.tangemSdk = tangemSdk
        vm.warningsConfigurator = warningsService
        vm.walletItemsRepository = walletItemsRepository
		if featuresService.isPayIdEnabled, let payIdService = PayIDService.make(from: blockchain) {
            vm.payIDService = payIdService
        }
        vm.updateState()
        return vm
    }
    
	func makeDisclaimerViewModel(with state: DisclaimerViewModel.State = .read) -> DisclaimerViewModel {
		// This is needed to prevent updating state of views that already in view hierarchy. Creating new model for each state
		// not so good solution, but this crucial when creating Navigation link without condition closures and Navigation link
		// recreates every redraw process. If you don't want to reinstantiate Navigation link, then functionality of pop to
		// specific View in navigation stack will be lost or push navigation animation will be disabled due to use of
		// StackNavigationViewStyle for NavigationView. Probably this is bug in current Apple realisation of NavigationView
		// and NavigationLinks - all navigation logic tightly coupled with View and redraw process.
		
		let name = String(describing: DisclaimerViewModel.self) + "_\(state)"
		let isTwin = cardsRepository.lastScanResult.cardModel?.isTwinCard ?? false
		if let vm: DisclaimerViewModel = get(key: name) {
            vm.isTwinCard = isTwin
			return vm
		}
		
		let vm = DisclaimerViewModel()
        vm.state = state
        vm.isTwinCard = isTwin
        vm.userPrefsService = userPrefsService
		initialize(vm, with: name)
        return vm
    }
    
    // MARK: Details
    
    func makeDetailsViewModel(with card: CardViewModel) -> DetailsViewModel {
        if let restored: DetailsViewModel = get() {
            restored.cardModel = card
            return restored
        }
        
        let vm =  DetailsViewModel(cardModel: card, dataCollector: DetailsFeedbackDataCollector(cardModel: card))
        initialize(vm)
        vm.cardsRepository = cardsRepository
        vm.ratesService = ratesService
        return vm
    }
    
    func makeSecurityManagementViewModel(with card: CardViewModel) -> SecurityManagementViewModel {
        if let restored: SecurityManagementViewModel = get() {
            return restored
        }
        
        let vm = SecurityManagementViewModel()
        initialize(vm)
        vm.cardViewModel = card
        return vm
    }
    
    func makeCurrencySelectViewModel() -> CurrencySelectViewModel {
        if let restored: CurrencySelectViewModel = get() {
            return restored
        }
        
        let vm =  CurrencySelectViewModel()
        initialize(vm)
        vm.ratesService = ratesService
        return vm
    }
    
//    func makeManageTokensViewModel(with walletModels: [WalletModel]) -> ManageTokensViewModel {
//        if let restored: ManageTokensViewModel = get() {
//            return restored
//        }
//
//        let vm = ManageTokensViewModel(walletModels: walletModels)
//        initialize(vm)
//        return vm
//    }
    
    func makeAddTokensViewModel(for cardModel: CardViewModel) -> AddNewTokensViewModel {
        if let restored: AddNewTokensViewModel = get() {
            return restored
        }
        
        let vm = AddNewTokensViewModel(cardModel: cardModel)
        initialize(vm)
        vm.walletItemsRepository = walletItemsRepository
        return vm
    }
    
    func makeAddCustomTokenViewModel(for wallet: WalletModel) -> AddCustomTokenViewModel {
        if let restored: AddCustomTokenViewModel = get() {
            return restored
        }
        let vm = AddCustomTokenViewModel(walletModel: wallet)
        initialize(vm)
        return vm
    }
    
    func makeSendViewModel(with amount: Amount, walletIndex: Int, card: CardViewModel) -> SendViewModel {
        if let restored: SendViewModel = get() {
            return restored
        }
        
        let vm = SendViewModel(walletIndex: walletIndex, amountToSend: amount, cardViewModel: card, signer: tangemSdk.signer, warningsManager: warningsService)
        initialize(vm)
        vm.ratesService = ratesService
        vm.featuresService = featuresService
        vm.emailDataCollector = SendScreenDataCollector(sendViewModel: vm)
        return vm
    }
	
    func makeTwinCardOnboardingViewModel(isFromMain: Bool) -> TwinCardOnboardingViewModel {
		let scanResult = cardsRepository.lastScanResult
        let twinInfo = scanResult.cardModel?.cardInfo.twinCardInfo
        let twinPairCid = TapTwinCardIdFormatter.format(cid: twinInfo?.pairCid ?? "", cardNumber: twinInfo?.series?.pair.number ?? 1)
		return makeTwinCardOnboardingViewModel(state: .onboarding(withPairCid: twinPairCid, isFromMain: isFromMain))
	}
	
    func makeTwinCardWarningViewModel(isRecreating: Bool) -> TwinCardOnboardingViewModel {
        makeTwinCardOnboardingViewModel(state: .warning(isRecreating: isRecreating))
	}
	
	func makeTwinCardOnboardingViewModel(state: TwinCardOnboardingViewModel.State) -> TwinCardOnboardingViewModel {
		let key = String(describing: TwinCardOnboardingViewModel.self) + "_" + state.storageKey
		if let vm: TwinCardOnboardingViewModel = get(key: key) {
            vm.state = state
			return vm
		}
		
		let vm = TwinCardOnboardingViewModel(state: state, imageLoader: imageLoaderService)
		initialize(vm, with: key)
		vm.userPrefsService = userPrefsService
		return vm
	}
	
	func makeTwinsWalletCreationViewModel(isRecreating: Bool) -> TwinsWalletCreationViewModel {
        if let twinInfo = cardsRepository.lastScanResult.cardModel!.cardInfo.twinCardInfo {
            twinsWalletCreationService.setupTwins(for: twinInfo)
        }
		if let vm: TwinsWalletCreationViewModel = get() {
			vm.walletCreationService = twinsWalletCreationService
			return vm
		}
		
		let vm = TwinsWalletCreationViewModel(isRecreatingWallet: isRecreating, walletCreationService: twinsWalletCreationService, imageLoaderService: imageLoaderService)
		initialize(vm)
		return vm
	}
    
    public func reset() {
        var persistentKeys = [String]()
        persistentKeys.append(String(describing: type(of: MainViewModel.self)))
        persistentKeys.append(String(describing: type(of: ReadViewModel.self)))
        persistentKeys.append(String(describing: DisclaimerViewModel.self) + "_\(DisclaimerViewModel.State.accept)")
        persistentKeys.append(String(describing: TwinCardOnboardingViewModel.self) + "_" + TwinCardOnboardingViewModel.State.onboarding(withPairCid: "", isFromMain: false).storageKey)
        
        let indicesToRemove = modelsStorage.keys.filter { !persistentKeys.contains($0) }
        indicesToRemove.forEach { modelsStorage.removeValue(forKey: $0) }
    }
    
    // MARK: - Private funcs
    
    private func initialize<V: ViewModel>(_ vm: V) {
        vm.navigation = navigationCoordinator
        vm.assembly = self
        store(vm)
    }
	
	private func initialize<V: ViewModel>(_ vm: V, with key: String) {
		vm.navigation = navigationCoordinator
		vm.assembly = self
		store(vm, with: key)
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
    
    private func onScan(_ cardInfo: CardInfo) {
        featuresService.setupFeatures(for: cardInfo.card)
        warningsService.setupWarnings(for: cardInfo.card)
        walletItemsRepository.setCard(cardInfo.card.cardId ?? "")
        
        if !featuresService.linkedTerminal {
            tangemSdk.config.linkedTerminal = false
        }
        
        if cardInfo.card.isTwinCard {
            tangemSdk.config.cardIdDisplayedNumbersCount = 4
        }
    }
}

extension Assembly {
    static var previewAssembly: Assembly = {
        let assembly = Assembly()
        
        // Twin card
        let twinScan = scanResult(for: Card.testTwinCard, assembly: assembly, twinCardInfo: TwinCardInfo(cid: "CB64000000006522", series: .cb64, pairCid: "CB65000000006521", pairPublicKey: nil))
        
        // Bitcoin old test card
        let testCardScan = scanResult(for: Card.testCard, assembly: assembly)
        
        // ETH pigeon card
        let ethCardScan = scanResult(for: Card.testEthCard, assembly: assembly)
        
        // Which card data should be displayed in preview?
        assembly.cardsRepository.lastScanResult = ethCardScan
        return assembly
    }()
    
    private static func scanResult(for card: Card, assembly: Assembly, twinCardInfo: TwinCardInfo? = nil) -> ScanResult {
        let ci = CardInfo(card: card,
                          artworkInfo: nil,
                          twinCardInfo: twinCardInfo)
        let vm = assembly.makeCardModel(from: ci)!
        let scanResult = ScanResult.card(model: vm)
        assembly.cardsRepository.cards[card.cardId!] = scanResult
        return scanResult
    }
}
