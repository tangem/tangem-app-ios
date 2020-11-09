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
    lazy var config = Config()
    
    lazy var tangemSdk: TangemSdk = {
        let sdk = TangemSdk()
        return sdk
    }()
    
    lazy var navigationCoordinator =  NavigationCoordinator()
    lazy var ratesService = CoinMarketCapService(apiKey: config.coinMarketCapApiKey)
    lazy var userPrefsService = UserPrefsService()
    lazy var networkService = NetworkService()
    lazy var workaroundsService = WorkaroundsService()
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
        crepo.ratesService = ratesService
        crepo.workaroundsService = workaroundsService
        return crepo
    }()
    
    func makeReadViewModel() -> ReadViewModel {
        let vm = ReadViewModel()
        initialize(vm)
        vm.userPrefsService = userPrefsService
        vm.cardsRepository = cardsRepository
        return vm
    }
    
    func makeMainViewModel() -> MainViewModel {
        let vm = MainViewModel()
        initialize(vm)
        vm.config = config
        vm.cardsRepository = cardsRepository
        vm.imageLoaderService = imageLoaderService
        vm.topupService = topupService
        vm.cardState = 
        return vm
    }
    
    func makeDisclaimerViewModel(with state: DisclaimerViewModel.State = .read) -> DisclaimerViewModel {
        let vm = DisclaimerViewModel()
        vm.state = state
        vm.userPrefsService = userPrefsService
        initialize(vm)
        return vm
    }
    
    func makeDetailsViewModel(with card: CardViewModel) -> DetailsViewModel {
        let vm = DetailsViewModel()
        initialize(vm)
        vm.cardsRepository = cardsRepository
        vm.cardViewModel = card
        return vm
    }
    
    func makeSecurityManagementViewModel(with card: CardViewModel) -> SecurityManagementViewModel {
        let vm = SecurityManagementViewModel()
        initialize(vm)
        vm.cardsRepository = cardsRepository
        vm.cardViewModel = card
        return vm
    }
    
    func makeSendViewModel(with amount: Amount, card: CardViewModel) -> SendViewModel {
        let vm = SendViewModel(amountToSend: amount, cardViewModel: card, signer: tangemSdk.signer)
        initialize(vm)
        return vm
    }
    
    private func initialize<V: ViewModel>(_ vm: V) {
        vm.navigation = navigationCoordinator
        vm.assembly = self
    }
}


extension Assembly {
    static var previewAssembly: Assembly {
        let assembly = Assembly()
        assembly.cardsRepository.cards[Card.testCard.cardId!] = CardViewModel(card: Card.testCard,
                                                                              walletManager: WalletManagerFactory().makeWalletManager(from: Card.testCard)!)
        return assembly
    }
}
