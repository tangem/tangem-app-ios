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
    
    func makeWalletConnectViewModel(cardModel: CardViewModel) -> WalletConnectViewModel {
        let vm = WalletConnectViewModel(cardModel: cardModel)
        initialize(vm)
        return vm
    }
    
    func makeAllWalletModels(from cardInfo: CardInfo) -> [WalletModel] {
        let assembly = WalletManagerAssembly()
        let walletManagers = assembly.makeAllWalletManagers(for: cardInfo)
        return makeWalletModels(walletManagers: walletManagers,
                                derivationStyle: cardInfo.card.derivationStyle,
                                isDemoCard: cardInfo.card.isDemoCard)
    }
    
    func makeWalletModels(from cardInfo: CardInfo, entries: [StorageEntry]) -> [WalletModel] {
        let assembly = WalletManagerAssembly()
        let walletManagers = assembly.makeWalletManagers(from: cardInfo, entries: entries)
        return makeWalletModels(walletManagers: walletManagers,
                                derivationStyle: cardInfo.card.derivationStyle,
                                isDemoCard: cardInfo.card.isDemoCard)
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
                                  isDemoCard: Bool) -> [WalletModel] {
        let items = SupportedTokenItems()
        return walletManagers.map { manager -> WalletModel in
            var demoBalance: Decimal? = nil
            if isDemoCard, let balance = items.predefinedDemoBalances[manager.wallet.blockchain] {
                demoBalance = balance
            }
            
            let model = WalletModel(walletManager: manager,
                                    derivationStyle: derivationStyle,
                                    demoBalance: demoBalance)
            
            model.initialize()
            return model
        }
    }
    
    private func initialize<V: ViewModel>(_ vm: V, isResetable: Bool = true) {
        store(vm, isResetable: isResetable)
    }
    
    private func initialize<V: ViewModel>(_ vm: V, with key: String, isResetable: Bool) {
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
