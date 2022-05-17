//
//  Assembly+App.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

extension Assembly {
    // MARK: - Onboarding
    func getLaunchOnboardingViewModel() -> OnboardingBaseViewModel {
        let key = "launch_onboarding_screen"
        if let restored: OnboardingBaseViewModel = get(key: key) {
            return restored
        }
        
        let vm = OnboardingBaseViewModel()
        initialize(vm, with: key, isResetable: false)
        
        return vm
    }
    
    func getLetsStartOnboardingViewModel() -> WelcomeOnboardingViewModel? {
        if let restored: WelcomeOnboardingViewModel = get() {
            return restored
        }
        
        return nil
    }
    
    func getLetsStartOnboardingViewModel(with callback: @escaping (OnboardingInput) -> Void) -> WelcomeOnboardingViewModel {
        if let restored: WelcomeOnboardingViewModel = get() {
            restored.successCallback = callback
            return restored
        }
        
        let vm = WelcomeOnboardingViewModel(successCallback: callback)
        initialize(vm, isResetable: false)
        return vm
    }
    
    func getCardOnboardingViewModel() -> OnboardingBaseViewModel {
        if let restored: OnboardingBaseViewModel = get() {
            return restored
        }
        
        return getLaunchOnboardingViewModel()
    }
    
    
    @discardableResult
    func makeCardOnboardingViewModel(with input: OnboardingInput) -> OnboardingBaseViewModel {
        let vm = OnboardingBaseViewModel(input: input)
        initialize(vm, isResetable: false)
        
        switch input.steps {
        case .singleWallet:
            makeNoteOnboardingViewModel(with: input)
        case .twins:
            makeTwinOnboardingViewModel(with: input)
        case .wallet:
            makeWalletOnboardingViewModel(with: input)
        }
        
        return vm
    }
    
    func getOnboardingViewModel() -> SingleCardOnboardingViewModel {
        if let restored: SingleCardOnboardingViewModel = get() {
            return restored
        }
        
        return makeNoteOnboardingViewModel(with: previewNoteCardOnboardingInput)
    }
    
    @discardableResult
    func makeNoteOnboardingViewModel(with input: OnboardingInput) -> SingleCardOnboardingViewModel {
        let vm = SingleCardOnboardingViewModel(input: input)
        initialize(vm, isResetable: false)
        return vm
    }
    
    func getTwinsOnboardingViewModel() -> TwinsOnboardingViewModel {
        if let restored: TwinsOnboardingViewModel = get() {
            return restored
        }
        
        return makeTwinOnboardingViewModel(with: previewTwinOnboardingInput)
    }
    
    @discardableResult
    func makeTwinOnboardingViewModel(with input: OnboardingInput) -> TwinsOnboardingViewModel {
        let vm = TwinsOnboardingViewModel(input: input)
        initialize(vm, isResetable: false)
        
        return vm
    }
    
    func getWalletOnboardingViewModel() -> WalletOnboardingViewModel {
        if let restored: WalletOnboardingViewModel = get() {
            return restored
        }
        
        return makeWalletOnboardingViewModel(with: previewWalletOnboardingInput)
    }
    
    //temp
    func getTwinOnboardingViewModel() -> TwinsOnboardingViewModel? {
        if let restored: TwinsOnboardingViewModel = get() {
            return restored
        }
        
        return nil
    }
    
    //temp
    func getWalletOnboardingViewModel() -> WalletOnboardingViewModel? {
        if let restored: WalletOnboardingViewModel = get() {
            return restored
        }
        
        return nil
    }
    
    @discardableResult
    func makeWalletOnboardingViewModel(with input: OnboardingInput) -> WalletOnboardingViewModel {
        let vm = WalletOnboardingViewModel(input: input)
        initialize(vm, isResetable: false)
        return vm
    }
    
    func makeWelcomeStoriesModel() -> StoriesViewModel {
        if let restored: StoriesViewModel = get() {
            return restored
        }
        
        let vm = StoriesViewModel()
        initialize(vm, isResetable: false)
        return vm
    }

    // MARK: - Main view model
    func makeMainViewModel() -> MainViewModel {
        if let restored: MainViewModel = get() {
            return restored
        }
        
        let vm =  MainViewModel()
        initialize(vm, isResetable: false)
        vm.updateState()
        return vm
    }
    
    func makeTotalSumBalanceViewModel(tokens: Published<[TokenItemViewModel]>.Publisher) -> TotalSumBalanceViewModel {
        let viewModel = TotalSumBalanceViewModel(tokens: tokens)
        return viewModel
    }
    
    func makeTokenDetailsViewModel(blockchainNetwork: BlockchainNetwork, amountType: Amount.AmountType = .coin) -> TokenDetailsViewModel {
        if let restored: TokenDetailsViewModel = get() {
            return restored
        }
        
        let vm =  TokenDetailsViewModel(blockchainNetwork: blockchainNetwork, amountType: amountType)
        initialize(vm)
        vm.updateState()
        return vm
    }
    
    // MARK: Card model
    func makeCardModel(from info: CardInfo) -> CardViewModel {
        let vm = CardViewModel(cardInfo: info)
        vm.initialize()
        vm.updateState()
        return vm
    }
    
    // MARK: - Details
    
    func makeDetailsViewModel() -> DetailsViewModel {
        
        if let restored: DetailsViewModel = get() {
            restored.updateState()
            return restored
        }
        
        let vm =  DetailsViewModel()
        initialize(vm)
        
        vm.updateState()
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
        return vm
    }
    
    func makeTokenListViewModel(mode: TokenListViewModel.Mode) -> TokenListViewModel {
        let restorationKey = "\(TokenListViewModel.self).\(mode.id)"
        if let restored: TokenListViewModel = get(key: restorationKey) {
            return restored
        }
        
        let vm = TokenListViewModel(mode: mode)
        initialize(vm, with: restorationKey, isResetable: true)
        return vm
    }
    
    func makeAddCustomTokenModel() -> AddCustomTokenViewModel {
        if let restored: AddCustomTokenViewModel = get() {
            return restored
        }
        
        let vm = AddCustomTokenViewModel()
        initialize(vm)
        vm.updateState()
        return vm
    }
    
    func makeSendViewModel(with amount: Amount, blockchainNetwork: BlockchainNetwork, card: CardViewModel) -> SendViewModel {
        if let restored: SendViewModel = get() {
            return restored
        }
        
        let vm: SendViewModel = SendViewModel(amountToSend: amount,
                                              blockchainNetwork: blockchainNetwork,
                                              cardViewModel: card)
        
        initialize(vm)
        return vm
    }
    
    func makeSellCryptoSendViewModel(with amount: Amount, destination: String, blockchainNetwork: BlockchainNetwork, card: CardViewModel) -> SendViewModel {
        if let restored: SendViewModel = get() {
            return restored
        }
        
        let vm = SendViewModel(amountToSend: amount,
                               destination: destination,
                               blockchainNetwork: blockchainNetwork,
                               cardViewModel: card)
        initialize(vm)
        return vm
    }
    
    func makePushViewModel(for tx: BlockchainSdk.Transaction, blockchainNetwork: BlockchainNetwork, card: CardViewModel) -> PushTxViewModel {
        if let restored: PushTxViewModel = get() {
            restored.transaction = tx
            return restored
        }
        
        let vm = PushTxViewModel(transaction: tx, blockchainNetwork: blockchainNetwork, cardViewModel: card)
        initialize(vm)
        return vm
    }
    
   
    func makeWalletConnectViewModel(cardModel: CardViewModel) -> WalletConnectViewModel {
        let vm = WalletConnectViewModel(cardModel: cardModel)
        initialize(vm)
        return vm
    }
    
    func makeShopViewModel() -> ShopViewModel {
        if let restored: ShopViewModel = get() {
            return restored
        }
        
        let vm = ShopViewModel()
        initialize(vm)
        return vm
    }
    
    func makeAllWalletModels(from cardInfo: CardInfo) -> [WalletModel] {
        let assembly = WalletManagerAssembly()
        let walletManagers = assembly.makeAllWalletManagers(for: cardInfo)
        return makeWalletModels(walletManagers: walletManagers,
                                derivationStyle: cardInfo.card.derivationStyle,
                                isDemoCard: cardInfo.card.isDemoCard,
                                defaultToken: cardInfo.defaultToken,
                                defaultBlockchain: cardInfo.defaultBlockchain)
    }
    
    func makeWalletModels(from cardInfo: CardInfo, entries: [StorageEntry]) -> [WalletModel] {
        let assembly = WalletManagerAssembly()
        let walletManagers = assembly.makeWalletManagers(from: cardInfo, entries: entries)
        return makeWalletModels(walletManagers: walletManagers,
                                derivationStyle: cardInfo.card.derivationStyle,
                                isDemoCard: cardInfo.card.isDemoCard,
                                defaultToken: cardInfo.defaultToken,
                                defaultBlockchain: cardInfo.defaultBlockchain)
    }
    
    func makeWalletModels(from cardDto: SavedCard, blockchainNetworks: [BlockchainNetwork]) -> [WalletModel] {
        let assembly = WalletManagerAssembly()
        let walletManagers = assembly.makeWalletManagers(from: cardDto, blockchainNetworks: blockchainNetworks)
        return makeWalletModels(walletManagers: walletManagers,
                                derivationStyle: cardDto.derivationStyle,
                                isDemoCard: false)
    }
    
    //Make walletModel from walletManager
    private func makeWalletModels(walletManagers: [WalletManager],
                                  derivationStyle: DerivationStyle,
                                  isDemoCard: Bool,
                                  defaultToken: BlockchainSdk.Token? = nil,
                                  defaultBlockchain: Blockchain? = nil) -> [WalletModel] {
        let items = SupportedTokenItems()
        return walletManagers.map { manager -> WalletModel in
            var demoBalance: Decimal? = nil
            if isDemoCard, let balance = items.predefinedDemoBalances[manager.wallet.blockchain] {
                demoBalance = balance
            }
            
            let model = WalletModel(walletManager: manager,
                                    derivationStyle: derivationStyle,
                                    defaultToken: defaultToken,
                                    defaultBlockchain: defaultBlockchain,
                                    demoBalance: demoBalance)
            
            model.initialize()
            return model
        }
    }
    
    private func initialize<V: ViewModel>(_ vm: V, isResetable: Bool = true) {
        vm.initialize()
        store(vm, isResetable: isResetable)
    }
    
    private func initialize<V: ViewModel>(_ vm: V, with key: String, isResetable: Bool) {
        vm.initialize()
        store(vm, with: key, isResetable: isResetable)
    }
    
    private func get<T>(key: String) -> T? {
        let val = (modelsStorage[key] ?? persistenceStorage[key]) as? ViewModel
        return val as? T
    }
    
    private func get<T>() -> T? {
        let key = String(describing: type(of: T.self))
        return get(key: key)
    }
    
    public func reset() {
        modelsStorage.removeAll()
    }
}
