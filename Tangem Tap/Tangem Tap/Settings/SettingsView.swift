//
//  SettingsView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemSdk

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        VStack {
            Button(action: {
                self.viewModel.purgeWallet()
            }) {
                Text("Purge Wallet")
            }.disabled(!viewModel.cardViewModel.canPurgeWallet)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    @State static var sdkService: TangemSdkService = {
        let service = TangemSdkService()
        service.cards[Card.testCard.cardId!] = CardViewModel(card: Card.testCard)
        service.cards[Card.testCardNoWallet.cardId!] = CardViewModel(card: Card.testCardNoWallet)
        return service
    }()
    
    @State static var cardWallet: CardViewModel = {
        return sdkService.cards[Card.testCard.cardId!]!
    }()
    
    @State static var cardNoWallet: CardViewModel = {
        return sdkService.cards[Card.testCardNoWallet.cardId!]!
    }()
    
    static var previews: some View {
        Group {
            SettingsView(viewModel: SettingsViewModel(
                cardViewModel: $cardWallet,
                sdkSerice: $sdkService))
            
            SettingsView(viewModel: SettingsViewModel(
                cardViewModel: $cardNoWallet,
                sdkSerice: $sdkService))
        }
    }
}
