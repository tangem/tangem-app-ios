//
//  DetailsViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import BlockchainSdk

class DetailsViewModel: ObservableObject {
    var sdkService: TangemSdkService
    var amountToSend: Amount? = nil
    
    @Published var cardViewModel: CardViewModel {
        didSet {
            bind()
        }
    }
    
    //Mark: Input
    @Published var isRefreshing = false
    @Published var showSettings = false
    @Published var showSend = false
    @Published var showSendChoise = false
    @Published var showCreatePayID = false
    
    //Mark: Output
    @Published var error: AlertBinder?
    @Published var isScanning: Bool = false
    @Published var isCreatingWallet: Bool = false
    
    public var canCreateWallet: Bool {
        return cardViewModel.wallet == nil && cardViewModel.isCardSupported
    }
    
    public var cardCanSign: Bool {
        let isPin2Default = cardViewModel.card.isPin2Default ?? true
        let hasSmartSecurityDelay = cardViewModel.card.settingsMask?.contains(.smartSecurityDelay) ?? false
        let canSkipSD = hasSmartSecurityDelay && !isPin2Default
        
        if let fw = cardViewModel.card.firmwareVersionValue, fw < 2.28 {
            if let securityDelay = cardViewModel.card.pauseBeforePin2, securityDelay > 1500 && !canSkipSD {
                return false
            }
        }
        
        return true
    }
    
    public var canSend: Bool {
        guard cardCanSign else {
            return false
        }
        
        guard let wallet = cardViewModel.wallet else {
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
        guard let wallet = cardViewModel.wallet else {
            return []
        }
        
        return wallet.transactions.filter { $0.destinationAddress == wallet.address
            && $0.status == .unconfirmed
            && $0.sourceAddress != "unknown" }
    }
    
    var outgoingTransactions: [BlockchainSdk.Transaction] {
        guard let wallet = cardViewModel.wallet else {
            return []
        }
        
        return wallet.transactions.filter { $0.sourceAddress == wallet.address
            && $0.status == .unconfirmed
            && $0.destinationAddress != "unknown"
        }
    }
    
    private var updateTimer: AnyCancellable? = nil
    private var bag = Set<AnyCancellable>()
    
    init(cid: String, sdkService: TangemSdkService) {
        self.sdkService = sdkService
        self.cardViewModel = sdkService.cards[cid]!
        bind()
    }
    
    func bind() {
        bag = Set<AnyCancellable>()
        $isRefreshing
            .removeDuplicates()
            .filter { $0 }
            .sink{ [unowned self] _ in
                self.cardViewModel.update()
        }
        .store(in: &bag)
        
        cardViewModel.$isWalletLoading
            .filter { !$0 }
            .receive(on: RunLoop.main)
            .assign(to: \.isRefreshing, on: self)
            .store(in: &bag)
        
        cardViewModel.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.objectWillChange.send()
        }
        .store(in: &bag)
        
        cardViewModel
            .walletManager?
            .$wallet
            .receive(on: RunLoop.main)
            .sink { [unowned self] wallet in
                if wallet.hasPendingTx {
                    if self.updateTimer == nil {
                        self.startUpdatingTimer()
                    }
                } else {
                    self.updateTimer = nil
                }
        }
        .store(in: &bag)               
    }
    
    
    func scan() {
        self.isScanning = true
        sdkService.scan { [weak self] scanResult in
            switch scanResult {
            case .success(let cardViewModel):
                self?.cardViewModel = cardViewModel
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
        self.isCreatingWallet = true
        sdkService.createWallet(card: cardViewModel.card) { [weak self] result in
            switch result {
            case .success(let cardViewModel):
                self?.cardViewModel = cardViewModel
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
        if let tokenAmount = cardViewModel.wallet!.amounts[.token], tokenAmount.value > 0 {
            showSendChoise = true
        } else {
            amountToSend = Amount(with: cardViewModel.wallet!.amounts[.coin]!, value: 0)
            showSend = true
        }
    }
    
    func showUntrustedDisclaimerIfNeeded() {
        if cardViewModel.card.cardType != .release {
            error = AlertManager().getAlert(.devCard, for: cardViewModel.card)
        } else {
            error = AlertManager().getAlert(.untrustedCard, for: cardViewModel.card)
        }
    }
    
    func onAppear() {
         showUntrustedDisclaimerIfNeeded()
    }
    
    func startUpdatingTimer() {
        updateTimer = Timer.TimerPublisher(interval: 10.0,
                                           tolerance: 0.1,
                                           runLoop: .main,
                                           mode: .common)
            .autoconnect()
            .sink() {[weak self] _ in
                self?.cardViewModel.update(silent: true)
        }
    }
}
