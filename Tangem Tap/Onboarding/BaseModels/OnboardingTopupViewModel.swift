//
//  OnboardingTopupViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

class OnboardingTopupViewModel<Step: OnboardingStep>: OnboardingViewModel<Step> {
    unowned var exchangeService: ExchangeService
    
    @Published var isAddressQrBottomSheetPresented: Bool = false
    @Published var refreshButtonState: OnboardingCircleButton.State = .refreshButton
    @Published var cardBalance: String = "0.00"
    
    var previewUpdates: Int = 0
    var walletModelUpdateCancellable: AnyCancellable?
    
    var cardModel: CardViewModel
    
    var canBuyCrypto: Bool { exchangeService.canBuyCrypto }
    
    var buyCryptoURL: URL? {
        if let wallet = cardModel.wallets?.first {
            return exchangeService.getBuyUrl(currencySymbol: wallet.blockchain.currencySymbol,
                                             walletAddress: wallet.address)
        }
        return nil
    }
    
    var buyCryptoCloseUrl: String { exchangeService.successCloseUrl.removeLatestSlash() }
    
    var shareAddress: String {
        cardModel.walletModels?.first?.shareAddressString(for: 0) ?? ""
    }
    
    var walletAddress: String {
        cardModel.walletModels?.first?.displayAddress(for: 0) ?? ""
    }
    
    init(exchangeService: ExchangeService, input: OnboardingInput) {
        self.exchangeService = exchangeService
        self.cardModel = input.cardModel
        super.init(input: input)
        
        if let walletModel = input.cardModel.walletModels?.first {
            updateCardBalanceText(for: walletModel)
        }
        updateCardBalance()
        
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
            let walletModel = cardModel.walletModels?.first,
            walletModelUpdateCancellable == nil
        else { return }
        
        
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
                        return
                    }
                    withAnimation {
                        self.refreshButtonState = .refreshButton
                    }
                case .failed(let error):
                    print(error)
                    withAnimation {
                        self.refreshButtonState = .refreshButton
                    }
                case .loading, .created:
                    return
                }
                self.walletModelUpdateCancellable = nil
            }
        walletModel.update(silent: false)
    }
    
    func updateCardBalanceText(for model: WalletModel) {
        withAnimation {
            cardBalance = model.getBalance(for: .coin)
        }
    }
    
}
