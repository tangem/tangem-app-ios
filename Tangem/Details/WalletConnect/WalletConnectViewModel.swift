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
import AVFoundation

class WalletConnectViewModel: ViewModel, ObservableObject {
    @Injected(\.walletConnectServiceProvider) private var walletConnectProvider: WalletConnectServiceProviding {
        didSet {
            bag.removeAll()

            $code
                .dropFirst()
                .sink {[unowned self] newCode in
                    if !self.walletConnectProvider.service.handle(url: newCode) {
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
            
            walletConnectProvider.service.isServiceBusy
                .receive(on: DispatchQueue.main)
                .sink { [weak self] (isServiceBusy) in
                    self?.isServiceBusy = isServiceBusy
                }
                .store(in: &bag)
            
            walletConnectProvider.service.sessionsPublisher
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: { [weak self] in
                    guard let self = self else { return }
                    
                    self.sessions = $0
                })
                .store(in: &bag)
        }
    }
    @Published var isActionSheetVisible: Bool = false
    @Published var showCameraDeniedAlert: Bool = false
    @Published var alert: AlertBinder?
    @Published var code: String = ""
    @Published var isServiceBusy: Bool = true
    @Published var sessions: [WalletConnectSession] = []
    
    var canCreateWC: Bool {
        cardModel.cardInfo.card.wallets.contains(where: { $0.curve == .secp256k1 })
            && (cardModel.wallets?.contains(where: { $0.blockchain == .ethereum(testnet: false) || $0.blockchain == .ethereum(testnet: true) }) ?? false)
    }
    
   private  var hasWCInPasteboard: Bool {
        guard let copiedValue = UIPasteboard.general.string else {
            return false
        }
        
        let canHandle = walletConnectProvider.service.canHandle(url: copiedValue)
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
        walletConnectProvider.service.disconnectSession(at: index)
        withAnimation {
            self.objectWillChange.send()
        }
    }
    
    func scanQrCode() {
        if case .denied = AVCaptureDevice.authorizationStatus(for: .video) {
            showCameraDeniedAlert = true
        } else {
            navigation.walletConnectToQR = true
        }
    }
    
    func pasteFromClipboard() {
        guard let value = copiedValue else { return }
        
        code = value
        copiedValue = nil
    }
    
    func openSession() {
        if cardModel.cardInfo.card.isDemoCard {
            alert = AlertBuilder.makeDemoAlert()
            return
        }
        
        if hasWCInPasteboard {
            isActionSheetVisible = true
        } else {
            scanQrCode()
        }
    }
}
