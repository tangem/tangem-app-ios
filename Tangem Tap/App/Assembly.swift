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
    
    lazy var tangemSdk: TangemSdk = {
        let sdk = TangemSdk()
        return sdk
    }()
    
    lazy var navigationCoordinator = NavigationCoordinator()
	lazy var ratesService = CoinMarketCapService(apiKey: keysManager.coinMarketKey)
    lazy var userPrefsService = UserPrefsService()
    lazy var networkService = NetworkService()
	lazy var walletManagerFactory = WalletManagerFactory(config: keysManager.blockchainConfig)
    lazy var featuresService = AppFeaturesService(configProvider: configManager)
    lazy var warningsService = WarningsService(remoteWarningProvider: configManager)
    lazy var imageLoaderService: ImageLoaderService = {
        return ImageLoaderService(networkService: networkService)
    }()
    lazy var topupService: TopupService = {
		let s = TopupService(keys: keysManager.moonPayKeys)
        return s
    }()
    
    lazy var cardsRepository: CardsRepository = {
        let crepo = CardsRepository(twinCardFileDecoder: TwinCardTlvFileDecoder(), warningsConfigurator: warningsService)
        crepo.tangemSdk = tangemSdk
        crepo.assembly = self
        crepo.featuresService = featuresService
        return crepo
    }()
	
	lazy var twinsWalletCreationService = {
		TwinsWalletCreationService(tangemSdk: tangemSdk,
								   twinFileEncoder: TwinCardTlvFileEncoder(),
								   cardsRepository: cardsRepository)
	}()
    
    private var modelsStorage = [String : Any]()
    
    func makeReadViewModel() -> ReadViewModel {
        if let restored: ReadViewModel = get() {
            return restored
        }
        
        let vm =  ReadViewModel()
        initialize(vm)
        vm.userPrefsService = userPrefsService
        vm.cardsRepository = cardsRepository
        return vm
    }
    
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
        return vm
    }
    
    func makeWalletModel(from cardInfo: CardInfo) -> WalletModel? {
		let card = cardInfo.card
		var pairKey: Data? = nil
		if card.isTwinCard {
			guard let savedPairKey = cardInfo.twinCardInfo?.pairPublicKey else {
				return nil
			}
			
			pairKey = savedPairKey
		}
		
        guard let walletManager = walletManagerFactory.makeWalletManager(from: card, pairKey: pairKey) else {
            return nil
        }
		
		return WalletModel(walletManager: walletManager, ratesService: ratesService)
    }
    
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
    
    func makeDetailsViewModel(with card: CardViewModel) -> DetailsViewModel {
        if let restored: DetailsViewModel = get() {
            restored.cardModel = card
            return restored
        }
        
        let vm =  DetailsViewModel(cardModel: card)
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
    
    func makeSendViewModel(with amount: Amount, card: CardViewModel) -> SendViewModel {
        if let restored: SendViewModel = get() {
            return restored
        }
        
        let vm = SendViewModel(amountToSend: amount, cardViewModel: card, signer: tangemSdk.signer, warningsManager: warningsService)
        initialize(vm)
        vm.ratesService = ratesService
        vm.featuresService = featuresService
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
    
    public func reset() {
        var persistentKeys = [String]()
        persistentKeys.append(String(describing: type(of: MainViewModel.self)))
        persistentKeys.append(String(describing: type(of: ReadViewModel.self)))
        persistentKeys.append(String(describing: DisclaimerViewModel.self) + "_\(DisclaimerViewModel.State.accept)")
        persistentKeys.append(String(describing: TwinCardOnboardingViewModel.self) + "_" + TwinCardOnboardingViewModel.State.onboarding(withPairCid: "", isFromMain: false).storageKey)
        
        let indicesToRemove = modelsStorage.keys.filter { !persistentKeys.contains($0) }
        indicesToRemove.forEach { modelsStorage.removeValue(forKey: $0) }
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
        let twinCard = Card.testTwinCard
        let ci = CardInfo(card: twinCard,
                          verificationState: nil,
                          artworkInfo: nil,
                          twinCardInfo: TwinCardInfo(cid: "CB64000000006522", series: .cb64, pairCid: "CB65000000006521", pairPublicKey: nil))
        let vm = assembly.makeCardModel(from: ci)!
        let scanResult = ScanResult.card(model: vm)
        assembly.cardsRepository.cards[twinCard.cardId!] = scanResult
        let testCard = Card.testCard
        let testCardCi = CardInfo(card: testCard, verificationState: nil, artworkInfo: nil, twinCardInfo: nil)
        let testCardVm = assembly.makeCardModel(from: testCardCi)!
        let testCardScan = ScanResult.card(model: testCardVm)
        assembly.cardsRepository.cards[testCard.cardId!] = testCardScan
        assembly.cardsRepository.lastScanResult = testCardScan
        return assembly
    }()
}
