//
//  SecurityManagementView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemSdk


enum SecurityManagementOption: CaseIterable, Identifiable {
    case longTap
    case passCode
    case accessCode
    
    var id: String { "\(self)" }
    
    var title: String {
        switch self {
        case .accessCode:
            return "manage_security_row_title_access_code".localized
        case .longTap:
            return "manage_security_row_title_longtap".localized
        case .passCode:
            return "manage_security_row_title_passcode".localized
        }
    }
    
    var subtitle: String {
        switch self {
        case .accessCode:
            return "manage_security_row_subtitle_access_code".localized
        case .longTap:
            return "manage_security_row_subtitle_longtap".localized
        case .passCode:
            return "manage_security_row_subtitle_passcode".localized
        }
    }
}

struct SecurityManagementRowView: View {
    var option: SecurityManagementOption
    
    @EnvironmentObject var cardViewModel: CardViewModel
    @EnvironmentObject var sdkService: TangemSdkService
    
    var isEnabled: Bool {
        switch option {
        case .accessCode:
            return cardViewModel.card.settingsMask?.contains(.allowSetPIN1) ?? false
        case .longTap:
            return cardViewModel.card.settingsMask?.contains(.allowSetPIN2) ?? false
        case .passCode:
            return !(cardViewModel.card.settingsMask?.contains(.prohibitDefaultPIN1) ?? false)
        }
    }
    
    var isSelected: Bool { cardViewModel.selectedSecOption == option }
    
    var body: some View {
        VStack (alignment: .leading, spacing: 0) {
            HStack (alignment: .lastTextBaseline) {
                Text(option.title)
                    .font(Font.system(size: 16.0, weight: .regular, design: .default))
                    .foregroundColor(.tangemTapGrayDark6)
                    .padding(.top, 16.0)
                    .padding([.bottom, .leading, .trailing], 8.0)
                    .opacity(isEnabled ? 1.0 : 0.5)
                Spacer()
                Image(isSelected ? "checkmark.circle.fill" : "circle")
                    .font(Font.system(size: 21.0, weight: .light, design: .default))
                    .foregroundColor(isSelected ? Color.tangemTapBlueLight : Color.tangemTapGrayLight4)
            }
            Text(option.subtitle)
                .font(Font.system(size: 13.0, weight: .medium, design: .default))
                .foregroundColor(.tangemTapGrayDark)
                .padding([.top, .leading, .trailing], 8.0)
                .padding(.bottom, 26.0)
                .opacity(isEnabled ? 1.0 : 0.5)
            
            
            NavigationLink(destination: CardOperationView(title: option.title,
                                                          alert: "cardOperation_security_management".localized,
                                                          actionButtonPressed: { completion in
                                                            self.sdkService.changeSecOption(self.option,
                                                                                            card: self.cardViewModel.card,
                                                                                            completion: completion) }))
            { EmptyView() }
                .disabled(!isEnabled || isSelected)
        }
    }
}


struct SecurityManagementView: View {
    var body: some View {
        List(SecurityManagementOption.allCases) { option in
            SecurityManagementRowView(option: option)
        }
        .listStyle(PlainListStyle())
        .background(Color.tangemTapBgGray.edgesIgnoringSafeArea(.all))
        .navigationBarTitle("manage_security_title", displayMode: .inline)
    }
}


struct SecurityManagementView_Previews: PreviewProvider {
    @State static var sdkService: TangemSdkService = {
        let service = TangemSdkService()
        service.cards[Card.testCard.cardId!] = CardViewModel(card: Card.testCard)
        service.cards[Card.testCardNoWallet.cardId!] = CardViewModel(card: Card.testCardNoWallet)
        return service
    }()
    
    @State static var cardWallet: CardViewModel = {
        return sdkService.cards[Card.testCard.cardId!]!
    }()
    
    static var previews: some View {
        SecurityManagementView()
            .environmentObject(cardWallet)
            .environmentObject(sdkService)
    }
}
