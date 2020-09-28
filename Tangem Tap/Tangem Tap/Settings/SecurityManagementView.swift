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
    @Binding var selectedOption: SecurityManagementOption
    let option: SecurityManagementOption
    
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
    
    var isSelected: Bool { selectedOption == option }
    
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
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if self.isEnabled {
                self.selectedOption = self.option
            }
        }
        .overlay(isEnabled ? Color.clear : Color.white.opacity(0.4))
    }
}


struct SecurityManagementView: View {
    @State private(set) var error: AlertBinder?
    @State private(set) var selectedOption: SecurityManagementOption
    @State private(set) var openWarning: Bool = false
    
    @EnvironmentObject var cardViewModel: CardViewModel
    @EnvironmentObject var sdkService: TangemSdkService
    
    var body: some View {
        VStack {
            List(SecurityManagementOption.allCases) { option in
                SecurityManagementRowView(selectedOption: self.$selectedOption, option: option)
            }
            .listStyle(PlainListStyle())
            
            HStack(alignment: .center, spacing: 8.0) {
                Spacer()
                Button(action: {
                    switch self.selectedOption {
                    case .accessCode, .passCode:
                        self.openWarning = true
                    case .longTap:
                        self.sdkService.changeSecOption(.longTap,
                                                        card: self.cardViewModel.card) { result in
                                                            switch result {
                                                            case .success:
                                                                break
                                                            case .failure(let error):
                                                                self.error = error.alertBinder
                                                            }
                        }
                    }
                }) { HStack(alignment: .center, spacing: 16.0) {
                    Text(selectedOption == .longTap ? "common_button_title_save_changes" : "common_continue")
                    Spacer()
                    Image("save")
                }.padding(.horizontal)
                }
                .buttonStyle(TangemButtonStyle(size: .big,
                                               colorStyle: .black,
                                               isDisabled: selectedOption == cardViewModel.currentSecOption))
                    .alert(item: self.$error) { $0.alert }
                    .disabled(selectedOption == cardViewModel.currentSecOption)
            }
            .padding(.horizontal, 16.0)
            .padding(.bottom, 16.0)
            
            if openWarning {
                NavigationLink(destination: CardOperationView(title: selectedOption.title,
                                                              alert: "cardOperation_security_management".localized,
                                                              actionButtonPressed: { completion in
                                                                self.sdkService.changeSecOption(self.selectedOption,
                                                                                                card: self.cardViewModel.card,
                                                                                                completion: completion) }),
                               isActive: $openWarning)
                {
                    EmptyView()
                    
                }
            }
        }
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
        SecurityManagementView(selectedOption: .longTap)
            .environmentObject(cardWallet)
            .environmentObject(sdkService)
    }
}
