//
//  WalletConnectViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

class WalletConnectViewModel: ViewModel, ObservableObject {
    weak var assembly: Assembly!
    weak var navigation: NavigationCoordinator!
    weak var walletConnectController: WalletConnectSessionController! {
        didSet {
            bag.removeAll()
            
            $code
                .dropFirst()
                .sink {[unowned self] newCode in
                    if !self.walletConnectController.handle(url: newCode) {
                        self.alert = WalletConnectServiceError.failedToConnect.alertBinder
                    }
                }
                .store(in: &bag)
            
//            walletConnectController.error
//                .receive(on: DispatchQueue.main)
//                .debounce(for: 0.3, scheduler: DispatchQueue.main)
//                .sink { error in
//                    self.alert = error.alertBinder
//                }
//                .store(in: &bag)
            
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
                    
                    self.sessions = $0
                })
                .store(in: &bag)
        }
    }
    
    @Published var alert: AlertBinder?
    @Published var code: String = ""
    @Published var isServiceBusy: Bool = true
    @Published var sessions: [WalletConnectSession] = []
    
    var canCreateWC: Bool {
        cardModel.cardInfo.card.wallets.contains(where: { $0.curve == .secp256k1 })
            && (cardModel.wallets?.contains(where: { $0.blockchain == .ethereum(testnet: false) || $0.blockchain == .ethereum(testnet: true) }) ?? false)
    }
    
    var hasWCInPasteboard: Bool {
        guard let copiedValue = UIPasteboard.general.string else {
            return false
        }
        
        let canHandle = walletConnectController.canHandle(url: copiedValue)
        if canHandle {
            self.copiedValue = copiedValue
        }
        return canHandle
    }
    
    private var cardModel: CardViewModel
    private var bag = Set<AnyCancellable>()
    private var copiedValue: String?
    
    init(cardModel: CardViewModel) {
        self.cardModel = cardModel
    }
    
    func disconnectSession(at index: Int) {
        walletConnectController.disconnectSession(at: index)
        withAnimation {
            self.objectWillChange.send()
        }
    }
    
    func scanQrCode() {
        navigation.walletConnectToQR = true
    }
    
    func pasteFromClipboard() {
        guard let value = copiedValue else { return }
        
        code = value
        copiedValue = nil
    }
}
