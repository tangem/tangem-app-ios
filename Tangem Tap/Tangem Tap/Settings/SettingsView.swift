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

struct DetailsRowView: View {
    var title: String
    var subtitle: String
    var body: some View {
        HStack (alignment: .center) {
            Text(title)
                .font(Font.system(size: 16.0, weight: .regular, design: .default))
                .foregroundColor(.tangemTapGrayDark6)
                .padding()
            Spacer()
            Text(subtitle)
                .font(Font.system(size: 16.0, weight: .regular, design: .default))
                .foregroundColor(.tangemTapGrayDark)
                .padding()
        }
        .listRowInsets(EdgeInsets())
    }
}

struct HeaderView: View {
    var text: String
    var body: some View {
        HStack {
            Text(text)
                .font(.headline)
                .foregroundColor(.tangemTapBlue)
                .padding()
            Spacer()
        }
        .padding(.top, 24.0)
        .background(Color.tangemTapBgGray)
        .listRowInsets(EdgeInsets())
    }
}


struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        List {
            Section(header: Color.tangemTapBgGray
                        .listRowInsets(EdgeInsets())) {
                DetailsRowView(title: "settings_row_title_cid".localized,
                               subtitle: CardIdFormatter(cid: viewModel.cardViewModel.card.cardId ?? "").formatted())
                DetailsRowView(title: "settings_row_title_issuer".localized,
                               subtitle: viewModel.cardViewModel.card.cardData?.issuerName ?? " ")
                if viewModel.cardViewModel.card.walletSignedHashes != nil {
                    DetailsRowView(title: "settings_row_title_signed".localized,
                                   subtitle: String(format: "settings_row_subtitle_signed_hashes_format".localized,
                                                    viewModel.cardViewModel.card.walletSignedHashes!.description))
                }
            }
            
            Section(header: HeaderView(text: "settings_section_title_settings".localized)) {
                NavigationLink(destination:CurrencySelectView()
                                .environmentObject(self.viewModel.cardViewModel)) {
                    DetailsRowView(title: "settings_row_title_currency".localized,
                                   subtitle: viewModel.cardViewModel.selectedCurrency)
                    
                }.listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
            }
            
            Section(header: HeaderView(text: "settings_section_title_card".localized)) {
                //                NavigationLink(destination:CurrencySelectView()) {
                //                    DetailsRowView(title: "settings_row_title_validate".localized, subtitle: "")
                //                }.listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
                
                //                NavigationLink(destination:CurrencySelectView()) {
                //                    DetailsRowView(title: "settings_row_title_manage_security".localized, subtitle: "Passcode")
                //                }.listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
                
                NavigationLink(destination: CardOperationView(title: "settings_row_title_erase_wallet".localized,
                                                              alert: "warning_erase_wallet".localized,
                                                              actionButtonPressed: { completion in
                                                                self.viewModel.sdkService.purgeWallet(cardId: nil) { result in
                                                                    switch result {
                                                                    case .success:
                                                                        completion(.success(()))
                                                                    case .failure(let error):
                                                                        completion(.failure(error))
                                                                    }
                                                                }
                                                              })
                ) {
                    DetailsRowView(title: "settings_row_title_erase_wallet".localized, subtitle: "")
                }.listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
                .disabled(!viewModel.cardViewModel.canPurgeWallet)
                
            }
            
            Section(header: Color.tangemTapBgGray
                        .listRowInsets(EdgeInsets())) {
                EmptyView()
            }
            
        }
        .listStyle(PlainListStyle())
        .background(Color.tangemTapBgGray.edgesIgnoringSafeArea(.all))
        .navigationBarTitle("settings_title", displayMode: .inline)
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
