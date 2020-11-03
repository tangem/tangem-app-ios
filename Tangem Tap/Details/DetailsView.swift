//
//  DetailsView.swift
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


struct DetailsView: View {
    @ObservedObject var viewModel: DetailsViewModel
    
    var body: some View {
        List {
            Section(header: EmptyView()
                .listRowInsets(EdgeInsets())) {
                    DetailsRowView(title: "details_row_title_cid".localized,
                                   subtitle: CardIdFormatter(cid: viewModel.cardViewModel.card.cardId ?? "").formatted())
                    DetailsRowView(title: "details_row_title_issuer".localized,
                                   subtitle: viewModel.cardViewModel.card.cardData?.issuerName ?? " ")
                    if viewModel.cardViewModel.card.walletSignedHashes != nil {
                        DetailsRowView(title: "details_row_title_signed_hashes".localized,
                                       subtitle: String(format: "details_row_subtitle_signed_hashes_format".localized,
                                                        viewModel.cardViewModel.card.walletSignedHashes!.description))
                    }
            }
            
            Section(header: HeaderView(text: "details_section_title_settings".localized)) {
                NavigationLink(destination:CurrencySelectView()
                    .environmentObject(self.viewModel.cardViewModel)) {
                        DetailsRowView(title: "details_row_title_currency".localized,
                                       subtitle: viewModel.cardViewModel.selectedCurrency)
                        
                }.listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
                
                NavigationLink(destination:DisclaimerView(viewModel: viewModel.assembly.makeDisclaimerViewModel(with: .read))
                                .background(Color.tangemTapBgGray.edgesIgnoringSafeArea(.all))) {
                                       DetailsRowView(title: "disclaimer_title".localized,
                                                      subtitle: "")
                                       
                               }.listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
            }
            
            Section(header: HeaderView(text: "details_section_title_card".localized)) {
                //                NavigationLink(destination:CurrencySelectView()) {
                //                    DetailsRowView(title: "details_row_title_validate".localized, subtitle: "")
                //                }.listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
                
                NavigationLink(destination: SecurityManagementView(viewModel: viewModel.assembly.makeSecurityManagementViewModel(with: viewModel.cardViewModel))) {
                        DetailsRowView(title: "details_row_title_manage_security".localized,
                                       subtitle: viewModel.cardViewModel.currentSecOption.title)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
                .disabled(!viewModel.canManageSecurity)
                
                NavigationLink(destination: CardOperationView(title: "details_row_title_erase_wallet".localized,
                                                              buttonTitle: "details_row_title_erase_wallet",
                                                              alert: "details_erase_wallet_warning".localized,
                                                              actionButtonPressed: {viewModel.purgeWallet(completion: $0)}
                )) {
                    DetailsRowView(title: "details_row_title_erase_wallet".localized, subtitle: "")
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
                .disabled(!viewModel.canPurgeWallet)
            }
            
            Section(header: Color.tangemTapBgGray
                .listRowInsets(EdgeInsets())) {
                    EmptyView()
            }
        }
        .padding(.top, 16.0)
        .background(Color.tangemTapBgGray.edgesIgnoringSafeArea(.all))
        .navigationBarTitle("details_title", displayMode: .inline)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        DetailsView(viewModel: Assembly.previewAssembly.makeDetailsViewModel(with: Assembly.previewAssembly.cardsRepository.cards.values.first!))
    }
}
