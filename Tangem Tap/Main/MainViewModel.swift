//
//  MainViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import BlockchainSdk
import TangemSdk

class MainViewModel: ViewModel {
    weak var imageLoaderService: ImageLoaderService!
    weak var topupService: TopupService!
    
    @Published var navigation: NavigationCoordinator! {
        didSet {
            navigation.objectWillChange
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    self?.objectWillChange.send()
                }
                .store(in: &persistentBag)
        }
    }
    weak var assembly: Assembly!
    var config: AppConfig!
    
    var amountToSend: Amount? = nil
    var persistentBag = Set<AnyCancellable>()
    var bag = Set<AnyCancellable>()
    var walletBag = Set<AnyCancellable>()
    weak var cardsRepository: CardsRepository!
    
    //Mark: Input
    @Published var isRefreshing = false
    
    //Mark: Output
    @Published var error: AlertBinder?
    @Published var isScanning: Bool = false
    @Published var isCreatingWallet: Bool = false
    @Published var image: UIImage? = nil
    @Published var state: ScanResult = .unsupported {
        didSet {
            bind()
        }
    }
    
    public var canCreateWallet: Bool {
        if let state = state.cardModel?.state,
           case .empty = state {
            return true
        }
        
        return false
    }
    
    var topupURL: URL? {
        if let wallet = state.wallet {
            return topupService.getTopupURL(currencySymbol: wallet.blockchain.currencySymbol,
                                     walletAddress: wallet.address)
        }
        return nil
    }
    
    var topupCloseUrl: String {
        return topupService.topupCloseUrl.removeLatestSlash()
    }
    
    public var canSend: Bool {
        guard let model = state.cardModel else {
            return false
        }
        
        guard model.canSign else {
            return false
        }
        
        guard let wallet = state.wallet else {
            return false
        }
        
        if wallet.hasPendingTx {
            return false
        }
        
        if wallet.amounts.isEmpty { //not loaded from blockchain
            return false
        }
        
        if wallet.amounts.values.first(where: { $0.value > 0 }) == nil { //empty wallet
            return false
        }
        
        let coinAmount = wallet.amounts[.coin]?.value ?? 0
        if coinAmount <= 0 { //not enough fee
            return false
        }
        
        return true
    }
    
    var incomingTransactions: [BlockchainSdk.Transaction] {
        guard let wallet = state.wallet else {
            return []
        }
        
        return wallet.transactions.filter { $0.destinationAddress == wallet.address
            && $0.status == .unconfirmed
            && $0.sourceAddress != "unknown"
        }
    }
    
    var outgoingTransactions: [BlockchainSdk.Transaction] {
        guard let wallet = state.wallet else {
            return []
        }
        
        return wallet.transactions.filter { $0.sourceAddress == wallet.address
            && $0.status == .unconfirmed
            && $0.destinationAddress != "unknown"
        }
    }
    

    func bind() {
        bag = Set<AnyCancellable>()
        
        
        state.cardModel?
            .objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &bag)
        
        state.cardModel?
            .$state
            .map { $0.walletModel }
            .receive(on: RunLoop.main)
            .sink { [unowned self] walletModel in
                self.walletBag = Set<AnyCancellable>()
                if let walletModel = walletModel {
                    walletModel.objectWillChange
                        .receive(on: RunLoop.main)
                        .sink { [unowned self] in
                            self.objectWillChange.send()
                        }
                        .store(in: &self.walletBag)
                    
                    walletModel.$state
                        .map { $0.isLoading }
                        .filter { !$0 }
                        .receive(on: RunLoop.main)
                        .assign(to: \.isRefreshing, on: self)
                        .store(in: &walletBag)
                }
            }
            .store(in: &bag)
        
        $isRefreshing
            .removeDuplicates()
            .filter { $0 }
            .sink{ [unowned self] _ in
                if let cardModel = self.state.cardModel {
                    cardModel.update()
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.isRefreshing = false
                    }
                }
                
            }
            .store(in: &bag)
        
        $state
            .compactMap { $0.cardModel?.cardInfo }
            .tryMap { cardInfo -> (String, Data, ArtworkInfo?) in
                if let cid = cardInfo.card.cardId,
                   let key = cardInfo.card.cardPublicKey  {
                    return (cid, key, cardInfo.artworkInfo)
                }
                
                throw "Some error"
            }
            .flatMap {[unowned self] info in
                return self.imageLoaderService
                    .loadImage(cid: info.0,
                               cardPublicKey: info.1,
                               artworkInfo: info.2)
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        Analytics.log(error: error)
                        print(error.localizedDescription)
                    case .finished:
                        break
                    }}){ [unowned self] image in
                self.image = image
            }
            .store(in: &bag)
    }
    
    func scan() {
        self.isScanning = true
        cardsRepository.scan { [weak self] scanResult in
            switch scanResult {
            case .success(let state):
                self?.assembly.reset()
                self?.state = state
                self?.showUntrustedDisclaimerIfNeeded()
            case .failure(let error):
                if case .unknownError = error.toTangemSdkError() {
                    self?.error = error.alertBinder
                }
            }
            self?.isScanning = false
        }
    }
    
    func createWallet() {
        guard let cardModel = state.cardModel else {
            return
        }
        
        self.isCreatingWallet = true
        cardModel.createWallet() { [weak self] result in
            switch result {
            case .success:
                break
            case .failure(let error):
                if case .userCancelled = error.toTangemSdkError() {
                    return
                }
                self?.error = error.alertBinder
            }
            self?.isCreatingWallet = false
        }
    }
    
    func sendTapped() {
        guard let wallet = state.wallet else {
            return
        }

        if let tokenAmount = wallet.amounts[.token], tokenAmount.value > 0 {
            navigation.showSendChoise = true
        } else {
            amountToSend = Amount(with: wallet.amounts[.coin]!, value: 0)
            showSendScreen() 
        }
    }
    
    func showSendScreen() {
        navigation.showSend = true
    }
    
    func showUntrustedDisclaimerIfNeeded() {
        guard let card = state.card else {
            return
        }
        
        if card.cardType != .release {
            error = AlertManager().getAlert(.devCard, for: card)
        } else {
            error = AlertManager().getAlert(.untrustedCard, for: card)
        }
    }
    
    func onAppear() {
        showUntrustedDisclaimerIfNeeded()
    }
}
