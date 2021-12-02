//
//  OnboardingTopupViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import BlockchainSdk

class OnboardingTopupViewModel<Step: OnboardingStep>: OnboardingViewModel<Step> {
    unowned var exchangeService: ExchangeService
    
    @Published var isAddressQrBottomSheetPresented: Bool = false
    @Published var refreshButtonState: OnboardingCircleButton.State = .refreshButton
    @Published var cardBalance: String = ""
    @Published var isBalanceRefresherVisible: Bool = false
    
    var previewUpdates: Int = 0
    var walletModelUpdateCancellable: AnyCancellable?
    
    var cardModel: CardViewModel?
    
    var buyCryptoURL: URL? {
        if let wallet = cardModel?.wallets?.first {
            return exchangeService.getBuyUrl(currencySymbol: wallet.blockchain.currencySymbol,
                                             blockchain: wallet.blockchain,
                                             walletAddress: wallet.address)
        }
        return nil
    }
    
    var buyCryptoCloseUrl: String { exchangeService.successCloseUrl.removeLatestSlash() }
    
    var shareAddress: String {
        cardModel?.walletModels?.first?.shareAddressString(for: 0) ?? ""
    }
    
    var walletAddress: String {
        cardModel?.walletModels?.first?.displayAddress(for: 0) ?? ""
    }
    
    var qrNoticeMessage: String {
        cardModel?.walletModels?.first?.getQRReceiveMessage() ?? ""
    }
    
    private var refreshButtonDispatchWork: DispatchWorkItem?
    
    init(exchangeService: ExchangeService, input: OnboardingInput) {
        self.exchangeService = exchangeService
        self.cardModel = input.cardInput.cardModel
        super.init(input: input)
        
        if let walletModel = self.cardModel?.walletModels?.first {
            updateCardBalanceText(for: walletModel)
        }
       // updateCardBalance()
        
    }
    
    func updateCardBalance() {
        if assembly?.isPreview ?? false {
            previewUpdates += 1
            
            if self.previewUpdates >= 3 {
                self.cardModel = Assembly.PreviewCard.scanResult(for: .cardanoNote, assembly: assembly).cardModel!
                self.previewUpdates = 0
            }
        }
        
        guard
            let walletModel = cardModel?.walletModels?.first,
            walletModelUpdateCancellable == nil
        else { return }
        
        if cardModel!.isNotPairedTwin { return }
        
        refreshButtonState = .activityIndicator
        walletModelUpdateCancellable = walletModel.$state
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .sink { [weak self] walletModelState in
                guard let self = self else { return }
                
                self.updateCardBalanceText(for: walletModel)
                switch walletModelState {
                case .noAccount(let message):
                    print(message)
                    fallthrough
                case .idle:
                    if !walletModel.isEmptyIncludingPendingIncomingTxs {
                        self.goToNextStep()
                        self.walletModelUpdateCancellable = nil
                        return
                    }
                    self.resetRefreshButtonState()
                case .failed(let error):
                    self.alert = error.alertBinder
                    self.resetRefreshButtonState()
                case .loading, .created:
                    return
                }
                self.walletModelUpdateCancellable = nil
            }
        walletModel.update(silent: false)
    }
    
    func updateCardBalanceText(for model: WalletModel) {
        if case .failed = model.state {
            cardBalance = "–"
            return
        }
        
        if model.wallet.amounts.isEmpty {
            cardBalance = Amount(with: model.wallet.blockchain, type: .coin, value: 0).string(with: 8)
        } else {
            cardBalance = model.getBalance(for: .coin)
        }
    }
    
    override func reset(includeInResetAnim: (() -> Void)? = nil) {
        walletModelUpdateCancellable = nil
        
        super.reset {
            self.previewUpdates = 0
            self.refreshButtonState = .refreshButton
            self.isBalanceRefresherVisible = false
            includeInResetAnim?()
        }
    }
    
    private func resetRefreshButtonState() {
//        guard refreshButtonDispatchWork == nil else { return }
//
//        refreshButtonDispatchWork = DispatchWorkItem(block: {
            withAnimation {
                self.refreshButtonState = .refreshButton
            }
//            self.refreshButtonDispatchWork = nil
//        })
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: refreshButtonDispatchWork!)
    }
    
}
