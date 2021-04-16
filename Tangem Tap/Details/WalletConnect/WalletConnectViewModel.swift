//
//  WalletConnectViewModel.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

class WalletConnectViewModel: ViewModel {
    weak var assembly: Assembly!
    weak var navigation: NavigationCoordinator!
    weak var walletConnectController: WalletConnectSessionController!
    
    @Published var alert: AlertBinder?
    @Published var code: String = ""
    @Published var isServiceBusy: Bool = true
    @Published var sessions: [WalletConnectSession] = []
    
    private var cardModel: CardViewModel
    private var bag = Set<AnyCancellable>()
    
    init(cardModel: CardViewModel) {
        self.cardModel = cardModel
    }
    
    func onAppear() {
        bag = []
        
        $code
            .dropFirst()
            .sink {[unowned self] newCode in
                if !self.walletConnectController.handle(url: newCode) {
                    self.alert = WalletConnectService.WalletConnectServiceError.failedToConnect.alertBinder
                }
            }
            .store(in: &bag)
        
        walletConnectController.error
            .receive(on: DispatchQueue.main)
            .sink {[unowned self]  error in
                self.alert = error.alertBinder
            }
            .store(in: &bag)
        
        walletConnectController.isServiceBusy
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (isServiceBusy) in
                self?.isServiceBusy = isServiceBusy
            }
            .store(in: &bag)
        
        walletConnectController.sessionsPublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] in
                guard let self = self else { return }
                
                self.sessions = $0.filter { $0.wallet.cid == self.cardModel.cardInfo.card.cardId }
            })
            .store(in: &bag)
    }
    
    func disconnectSession(at index: Int) {
        walletConnectController.disconnectSession(at: index)
        withAnimation {
            self.objectWillChange.send()
        }
    }
    
    func openNewSession() {
        navigation.walletConnectToQR = true
    }
}
