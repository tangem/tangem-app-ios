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
    weak var walletConnectService: WalletConnectService!
    weak var walletConnectController: WalletConnectSessionController!
    
    @Published var error: AlertBinder?
    @Published var code: String = ""
    @Published var isServiceBusy: Bool = true
    
    private var bag = Set<AnyCancellable>()
    
    init() {}
    
    func onAppear() {
        bag = []
        
        $code
            .dropFirst()
            .sink {[unowned self] newCode in
                if self.walletConnectService.handle(url: newCode) {
//                    self.isConnecting = true
                } else {
                    self.error = WalletConnectService.WalletConnectServiceError.failedToConnect.alertBinder
                }
            }
            .store(in: &bag)
        
        walletConnectService.error
            .receive(on: DispatchQueue.main)
            .sink {[unowned self]  error in
                self.error = error.alertBinder
            }
            .store(in: &bag)
        
        walletConnectController.isServiceBusy
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (isServiceBusy) in
                self?.isServiceBusy = isServiceBusy
            }
            .store(in: &bag)
    }
    
    func disconnectSession(at index: Int) {
        walletConnectService.disconnectSession(at: index)
        withAnimation {
            self.objectWillChange.send()
        }
    }
    
    func openNewSession() {
        navigation.walletConnectToQR = true
    }
}
