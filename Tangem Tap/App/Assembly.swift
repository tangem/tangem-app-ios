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
    lazy var config = AppConfig()
    
    lazy var tangemSdk: TangemSdk = {
        let sdk = TangemSdk()
        return sdk
    }()
    
    lazy var navigationCoordinator = NavigationCoordinator()
    lazy var ratesService = CoinMarketCapService(apiKey: config.coinMarketCapApiKey)
    lazy var userPrefsService = UserPrefsService()
    lazy var networkService = NetworkService()
    lazy var walletManagerFactory = WalletManagerFactory()
    lazy var featuresService = AppFeaturesService()
    lazy var imageLoaderService: ImageLoaderService = {
        return ImageLoaderService(networkService: networkService)
    }()
    lazy var topupService: TopupService = {
        let s = TopupService()
        s.config = config
        return s
    }()
    
    lazy var cardsRepository: CardsRepository = {
		let crepo = CardsRepository(twinCardFileDecoder: TwinCardTlvFileDecoder())
        crepo.tangemSdk = tangemSdk
        crepo.assembly = self
        crepo.featuresService = featuresService
        return crepo
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
			restored.state = cardsRepository.lastScanResult
            return restored
        }
        let vm =  MainViewModel()
        initialize(vm)
        vm.config = config
        vm.cardsRepository = cardsRepository
        vm.imageLoaderService = imageLoaderService
        vm.topupService = topupService
        vm.state = cardsRepository.lastScanResult
		vm.userPrefsService = userPrefsService
        return vm
    }
    
    func makeWalletModel(from card: Card) -> WalletModel? {
        if let walletManager = walletManagerFactory.makeWalletManager(from: card) {
            let wm = WalletModel(walletManager: walletManager)
            wm.ratesService = ratesService
            return wm
        } else {
            return nil
        }
    }
    
    func makeCardModel(from info: CardInfo) -> CardViewModel? {
        guard let blockchainName = info.card.cardData?.blockchainName,
              let curve = info.card.curve,
              let blockchain = Blockchain.from(blockchainName: blockchainName, curve: curve) else {
            return nil
        }
        
        let vm = CardViewModel(cardInfo: info)
        vm.featuresService = featuresService
        vm.config = config
        vm.assembly = self
        vm.tangemSdk = tangemSdk
        if config.isEnablePayID, let payIdService = PayIDService.make(from: blockchain) {
            payIdService.featuresService = featuresService
            vm.payIDService = payIdService
        }
        
        vm.updateState()
        vm.update()
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
			vm.state = state
			return vm
		}
		
		let vm = DisclaimerViewModel(isTwinCard: isTwin)
        vm.state = state
        vm.userPrefsService = userPrefsService
		initialize(vm, with: name)
        return vm
    }
    
    func makeDetailsViewModel(with card: CardViewModel) -> DetailsViewModel {

        if let restored: DetailsViewModel = get() {
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
        
        let vm = SendViewModel(amountToSend: amount, cardViewModel: card, signer: tangemSdk.signer)
        initialize(vm)
        vm.ratesService = ratesService
        return vm
    }
	
	func makeTwinCardOnboardingViewModel(isFromMain: Bool) -> TwinCardOnboardingViewModel {
		let scanResult = cardsRepository.lastScanResult
		let twinPairCid = scanResult.cardModel?.cardInfo.twinCardInfo?.pairCid
		return makeTwinCardOnboardingViewModel(state: .onboarding(withPairCid: twinPairCid ?? "", isFromMain: isFromMain))
	}
	
	func makeTwinCardWarningViewModel() -> TwinCardOnboardingViewModel {
		makeTwinCardOnboardingViewModel(state: .warning)
	}
	
	func makeTwinCardOnboardingViewModel(state: TwinCardOnboardingViewModel.State) -> TwinCardOnboardingViewModel {
		let key = String(describing: TwinCardOnboardingView.self) + "_" + state.storageKey
		if let vm: TwinCardOnboardingViewModel = get(key: key) {
			return vm
		}
		
		let vm = TwinCardOnboardingViewModel(state: state)
		initialize(vm, with: key)
		vm.userPrefsService = userPrefsService
		vm.imageLoader = imageLoaderService
		return vm
	}
	
	func makeTwinsWalletCreationViewModel(isRecreating: Bool) -> TwinsWalletCreationViewModel {
		let service = TwinsWalletCreationService(tangemSdk: tangemSdk,
												 twinFileEncoder: TwinCardTlvFileEncoder(),
												 twinInfo: cardsRepository.lastScanResult.cardModel!.cardInfo.twinCardInfo!)
		
		if let vm: TwinsWalletCreationViewModel = get() {
			vm.walletCreationService = service
			return vm
		}
		
		let vm = TwinsWalletCreationViewModel(isRecreatingWallet: isRecreating, walletCreationService: service)
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
        let mainKey = String(describing: type(of: MainViewModel.self))
        let readKey = String(describing: type(of: ReadViewModel.self))
        
        let indicesToRemove = modelsStorage.keys.filter { $0 != mainKey && $0 != readKey }
        indicesToRemove.forEach { modelsStorage.removeValue(forKey: $0) }
    }
	
    private func store<T>(_ object: T ) {
        let key = String(describing: type(of: T.self))
        store(object, with: key)
    }
	
	private func store<T>(_ object: T, with key: String) {
		print(key)
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
        let ci = CardInfo(card: Card.testTwinCard,
                          verificationState: nil,
						  artworkInfo: nil,
						  twinCardInfo: TwinCardInfo(cid: "BB04000000006522", series: .dev4, pairCid: "BB05000000006521", pairPublicKey: nil))
        let vm = assembly.makeCardModel(from: ci)!
        let scanResult = ScanResult.card(model: vm)
        assembly.cardsRepository.cards[Card.testCard.cardId!] = scanResult
		assembly.cardsRepository.lastScanResult = scanResult
        return assembly
    }()
}
