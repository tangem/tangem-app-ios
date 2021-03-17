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

class ServicesAssembly {
    weak var assembly: Assembly!
    
    deinit {
        print("ServicesAssembly deinit")
    }
    
    let logger = Logger()
    lazy var navigationCoordinator = NavigationCoordinator()
    lazy var ratesService = CoinMarketCapService(apiKey: keysManager.coinMarketKey)
    lazy var userPrefsService = UserPrefsService()
    lazy var networkService = NetworkService()
    lazy var walletManagerFactory = WalletManagerFactory(config: keysManager.blockchainConfig)
    lazy var featuresService = AppFeaturesService(configProvider: configManager)
    lazy var warningsService = WarningsService(remoteWarningProvider: configManager, rateAppChecker: rateAppService)
    lazy var persistentStorage = PersistentStorage()
    lazy var tokenItemsRepository = TokenItemsRepository(persistanceStorage: persistentStorage)
    lazy var keychainService = ValidatedCardsService()
    lazy var imageLoaderService: ImageLoaderService = ImageLoaderService(networkService: networkService)
    lazy var rateAppService: RateAppService = .init(userPrefsService: userPrefsService)
    lazy var topupService: TopupService = .init(keys: keysManager.moonPayKeys)
    lazy var tangemSdk: TangemSdk = .init()
    
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
    
    lazy var cardsRepository: CardsRepository = {
        let crepo = CardsRepository()
        crepo.tangemSdk = tangemSdk
        crepo.validatedCardsService = keychainService
        crepo.assembly = assembly
        crepo.delegate = self
        return crepo
    }()
    
    lazy var twinsWalletCreationService = {
        TwinsWalletCreationService(tangemSdk: tangemSdk,
                                   twinFileEncoder: TwinCardTlvFileEncoder(),
                                   cardsRepository: cardsRepository,
                                   validatedCardsService: keychainService)
    }()
    
    private let keysManager = try! KeysManager()
    private let configManager = try! FeaturesConfigManager()
    
    private lazy var defaultSdkConfig: Config = {
        var config = Config()
        config.logСonfig = Log.Config.custom(logLevel: Log.Level.allCases, loggers: [logger])
        return config
    }()
    
    
}

extension ServicesAssembly: CardsRepositoryDelegate {
    func onDidScan(_ cardInfo: CardInfo) {
        featuresService.setupFeatures(for: cardInfo.card)
        warningsService.setupWarnings(for: cardInfo.card)
        tokenItemsRepository.setCard(cardInfo.card.cardId ?? "")
        
        if !featuresService.linkedTerminal {
            tangemSdk.config.linkedTerminal = false
        }
        
        if cardInfo.card.isTwinCard {
            tangemSdk.config.cardIdDisplayedNumbersCount = 4
        }
    }
    
    func onWillScan() {
        tangemSdk.config = defaultSdkConfig
    }
}

class Assembly: ObservableObject {
    public let services: ServicesAssembly
    private var modelsStorage = [String : Any]()
    
    init() {
        services = ServicesAssembly()
        services.assembly = self
    }
    
    deinit {
        print("Assembly deinit")
    }
    
    func makeReadViewModel() -> ReadViewModel {
        if let restored: ReadViewModel = get() {
            return restored
        }
        
        let vm =  ReadViewModel()
        initialize(vm)
        vm.failedCardScanTracker = services.failedCardScanTracker
        vm.userPrefsService = services.userPrefsService
        vm.cardsRepository = services.cardsRepository
        return vm
    }
    
    // MARK: Main view model
    func makeMainViewModel() -> MainViewModel {
        if let restored: MainViewModel = get() {
            let restoredCid = restored.state.card?.cardId ?? ""
            let newCid = services.cardsRepository.lastScanResult.card?.cardId ?? ""
            if restoredCid != newCid {
                restored.state = services.cardsRepository.lastScanResult
            }
            return restored
        }
        let vm =  MainViewModel()
        initialize(vm)
        vm.cardsRepository = services.cardsRepository
        vm.imageLoaderService = services.imageLoaderService
        vm.topupService = services.topupService
        vm.userPrefsService = services.userPrefsService
        vm.warningsManager = services.warningsService
        vm.state = services.cardsRepository.lastScanResult
        vm.rateAppController = services.rateAppService

        vm.negativeFeedbackDataCollector = services.negativeFeedbackDataCollector
        vm.failedCardScanTracker = services.failedCardScanTracker
        
        return vm
    }
    
    func makeTokenDetailsViewModel( blockchain: Blockchain, amountType: Amount.AmountType = .coin) -> TokenDetailsViewModel {
        let vm =  TokenDetailsViewModel(blockchain: blockchain, amountType: amountType)
        initialize(vm)
        if let cardModel = services.cardsRepository.lastScanResult.cardModel {
            vm.card = cardModel
        }
        vm.topupService = services.topupService
        return vm
    }
    
    func makeWalletModels(from cardInfo: CardInfo, blockchains: [Blockchain]) -> [WalletModel] {
        let walletManagers = services.walletManagerFactory.makeWalletManagers(from: cardInfo.card, blockchains: blockchains)
        let models = walletManagers.map { manager -> WalletModel in
            let model = WalletModel(cardInfo: cardInfo, walletManager: manager)
            model.tokenItemsRepository = services.tokenItemsRepository
            model.ratesService = services.ratesService
            return model
        }
        return models
    }
    
    func makeWalletModel(from cardInfo: CardInfo) -> [WalletModel] {
        return makeWallets(from: cardInfo).map {
            let model = WalletModel(cardInfo: cardInfo, walletManager: $0)
            model.tokenItemsRepository = services.tokenItemsRepository
            model.ratesService = services.ratesService
            return model
        }
    }
    
    private func makeWallets(from cardInfo: CardInfo) -> [WalletManager] {
        if cardInfo.card.isTwinCard,
           let savedPairKey = cardInfo.twinCardInfo?.pairPublicKey,
           let twinWalletManager = services.walletManagerFactory.makeTwinWalletManager(from: cardInfo.card, pairKey: savedPairKey) {
            return [twinWalletManager]
        }

        if cardInfo.card.isMultiWallet && services.tokenItemsRepository.items.count > 0 {
            return makeMultiwallet(from: cardInfo.card)
        }
        
        if let cardWalletManager = services.walletManagerFactory.makeWalletManager(from: cardInfo.card) {
            return [cardWalletManager]
        }
        
        return []
    }
    
    private func makeMultiwallet(from card: Card) -> [WalletManager] {
        var walletManagers: [WalletManager] = .init()
        
        let erc20Tokens = services.tokenItemsRepository.items.compactMap { $0.token }
        if !erc20Tokens.isEmpty {
            if let ethereumWalletManager = services.walletManagerFactory.makeEthereumWalletManager(from: card, erc20Tokens: erc20Tokens) {
                walletManagers.append(ethereumWalletManager)
            }
        }
        
        if walletManagers.first(where: { $0.wallet.blockchain == card.blockchain}) == nil,
           let nativeWalletManager = services.walletManagerFactory.makeWalletManager(from: card) {
            walletManagers.append(nativeWalletManager)
        }
        
        let existingBlockchains = walletManagers.map { $0.wallet.blockchain }
        let additionalBlockchains = services.tokenItemsRepository.items.compactMap ({ $0.blockchain }).filter{ !existingBlockchains.contains($0) }
        let additionalWalletManagers = services.walletManagerFactory.makeWalletManagers(from: card, blockchains: additionalBlockchains)
        walletManagers.append(contentsOf: additionalWalletManagers)
        return walletManagers
    }
    
    // MARK: Card model
    func makeCardModel(from info: CardInfo) -> CardViewModel? {
        guard let blockchainName = info.card.cardData?.blockchainName,
              let curve = info.card.curve,
              let blockchain = Blockchain.from(blockchainName: blockchainName, curve: curve) else {
            return nil
        }
        
        let vm = CardViewModel(cardInfo: info)
        vm.featuresService = services.featuresService
        vm.assembly = self
        vm.tangemSdk = services.tangemSdk
        vm.warningsConfigurator = services.warningsService
        vm.warningsAppendor = services.warningsService
        vm.tokenItemsRepository = services.tokenItemsRepository
        if services.featuresService.isPayIdEnabled, let payIdService = PayIDService.make(from: blockchain) {
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
        let isTwin = services.cardsRepository.lastScanResult.cardModel?.isTwinCard ?? false
		if let vm: DisclaimerViewModel = get(key: name) {
            vm.isTwinCard = isTwin
			return vm
		}
		
		let vm = DisclaimerViewModel()
        vm.state = state
        vm.isTwinCard = isTwin
        vm.userPrefsService = services.userPrefsService
		initialize(vm, with: name)
        return vm
    }
    
    // MARK: Details
    
    func makeDetailsViewModel() -> DetailsViewModel {
        
        if let restored: DetailsViewModel = get() {
            if let cardModel = services.cardsRepository.lastScanResult.cardModel {
                restored.cardModel = cardModel
            }
            return restored
        }
        
        let vm =  DetailsViewModel()
        initialize(vm)
        
        if let cardModel = services.cardsRepository.lastScanResult.cardModel {
            vm.cardModel = cardModel
            vm.dataCollector = DetailsFeedbackDataCollector(cardModel: cardModel)
        }
        vm.cardsRepository = services.cardsRepository
        vm.ratesService = services.ratesService
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
        vm.ratesService = services.ratesService
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
        vm.tokenItemsRepository = services.tokenItemsRepository
        return vm
    }
    
//    func makeAddCustomTokenViewModel(for wallet: WalletModel) -> AddCustomTokenViewModel {
//        if let restored: AddCustomTokenViewModel = get() {
//            return restored
//        }
//        let vm = AddCustomTokenViewModel(walletModel: wallet)
//        initialize(vm)
//        return vm
//    }
    
    func makeSendViewModel(with amount: Amount, walletIndex: Int, card: CardViewModel) -> SendViewModel {
        if let restored: SendViewModel = get() {
            return restored
        }
        
        let vm = SendViewModel(walletIndex: walletIndex,
                               amountToSend: amount,
                               cardViewModel: card,
                               signer: services.tangemSdk.signer,
                               warningsManager: services.warningsService)
        initialize(vm)
        vm.ratesService = services.ratesService
        vm.featuresService = services.featuresService
        vm.emailDataCollector = SendScreenDataCollector(sendViewModel: vm)
        return vm
    }
	
    func makeTwinCardOnboardingViewModel(isFromMain: Bool) -> TwinCardOnboardingViewModel {
        let scanResult = services.cardsRepository.lastScanResult
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
		
        let vm = TwinCardOnboardingViewModel(state: state, imageLoader: services.imageLoaderService)
		initialize(vm, with: key)
        vm.userPrefsService = services.userPrefsService
		return vm
	}
	
	func makeTwinsWalletCreationViewModel(isRecreating: Bool) -> TwinsWalletCreationViewModel {
        if let twinInfo = services.cardsRepository.lastScanResult.cardModel!.cardInfo.twinCardInfo {
            services.twinsWalletCreationService.setupTwins(for: twinInfo)
        }
		if let vm: TwinsWalletCreationViewModel = get() {
            vm.walletCreationService = services.twinsWalletCreationService
			return vm
		}
		
		let vm = TwinsWalletCreationViewModel(isRecreatingWallet: isRecreating,
                                              walletCreationService: services.twinsWalletCreationService,
                                              imageLoaderService: services.imageLoaderService)
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
        vm.navigation = services.navigationCoordinator
        vm.assembly = self
        store(vm)
    }
	
	private func initialize<V: ViewModel>(_ vm: V, with key: String) {
        vm.navigation = services.navigationCoordinator
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
        assembly.services.cardsRepository.lastScanResult = ethCardScan
        return assembly
    }()
    
    private static func scanResult(for card: Card, assembly: Assembly, twinCardInfo: TwinCardInfo? = nil) -> ScanResult {
        let ci = CardInfo(card: card,
                          artworkInfo: nil,
                          twinCardInfo: twinCardInfo)
        let vm = assembly.makeCardModel(from: ci)!
        let scanResult = ScanResult.card(model: vm)
        assembly.services.cardsRepository.cards[card.cardId!] = scanResult
        return scanResult
    }
}
