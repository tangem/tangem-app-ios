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
    let config = AppConfig()
    
    lazy var tangemSdk: TangemSdk = {
        let sdk = TangemSdk()
        return sdk
    }()
    
    lazy var navigationCoordinator = NavigationCoordinator()
    lazy var ratesService = CoinMarketCapService(apiKey: config.coinMarketCapApiKey)
    lazy var userPrefsService = UserPrefsService()
    lazy var networkService = TmpNetworkService()
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
        let crepo = CardsRepository()
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
            return restored
        }
        let vm =  MainViewModel()
        initialize(vm)
        vm.config = config
        vm.cardsRepository = cardsRepository
        vm.imageLoaderService = imageLoaderService
        vm.topupService = topupService
        vm.state = cardsRepository.cards.first!.value
        return vm
    }
    
    func makeWalletModel(from card: Card) -> WalletModel? {
        if let walletManager = walletManagerFactory.makeWalletManager(from: card) {
            let wm = WalletModel(walletManager: walletManager, ratesService: ratesService)
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
            vm.payIDService = payIdService
        }
        vm.update()
        return vm
    }
    
    func makeDisclaimerViewModel(with state: DisclaimerViewModel.State = .read) -> DisclaimerViewModel {
        if let restored: DisclaimerViewModel = get() {
            return restored
        }
        
        let vm =  DisclaimerViewModel()
        vm.state = state
        vm.userPrefsService = userPrefsService
        initialize(vm)
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
        vm.featuresService = featuresService
        return vm
    }
    
    private func initialize<V: ViewModel>(_ vm: V) {
        vm.navigation = navigationCoordinator
        vm.assembly = self
        store(vm)
    }
    
    public func reset() {
        let mainKey = String(describing: type(of: MainViewModel.self))
        let readKey = String(describing: type(of: ReadViewModel.self))
        
        let indicesToRemove = modelsStorage.keys.filter { $0 != mainKey && $0 != readKey }
        indicesToRemove.forEach { modelsStorage.removeValue(forKey: $0) }
    }
    
    private func store<T>(_ object: T ) {
        let key = String(describing: type(of: T.self))
        print(key)
        modelsStorage[key] = object
    }
    
    private func get<T>() -> T? {
        let key = String(describing: type(of: T.self))
        return (modelsStorage[key] as? T)
    }
}

extension Assembly {
    static var previewAssembly: Assembly {
        let assembly = Assembly()
        let ci = CardInfo(card: Card.testCard,
                          verificationState: nil,
                          artworkInfo: nil)
        let vm = assembly.makeCardModel(from: ci)!
        let scanResult = ScanResult.card(model: vm)
        assembly.cardsRepository.cards[Card.testCard.cardId!] = scanResult
        return assembly
    }
}
