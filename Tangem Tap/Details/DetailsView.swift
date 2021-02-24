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
    var additionalTopPadding: CGFloat = 0
    var body: some View {
        HStack {
            Text(text)
                .font(.headline)
                .foregroundColor(.tangemTapBlue)
                .padding(16)
            Spacer()
        }
        .padding(.top, additionalTopPadding)
        .background(Color.tangemTapBgGray)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
}

struct FooterView: View {
    var text: String = ""
    var additionalBottomPadding: CGFloat = 0
    var body: some View {
        if text.isEmpty {
            Color.tangemTapBgGray
                .listRowBackground(Color.tangemTapBgGray)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .frame(height: 0)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                Text(text)
                    .font(.footnote)
                    .foregroundColor(.tangemTapGrayDark)
                    .padding()
                    .padding(.bottom, additionalBottomPadding)
                Color.clear.frame(height: 0)
            }
            .background(Color.tangemTapBgGray)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        }
    }
}

struct DetailsDestination: Identifiable {
    let id: Int
    let destination: AnyView
}

struct DetailsView: View {
    @ObservedObject var viewModel: DetailsViewModel
    @EnvironmentObject var navigation: NavigationCoordinator
    @State var selection: String? = nil //fix remain highlited bug on ios14
    
    var body: some View {
        List {
            Section(header: EmptyView().listRowInsets(EdgeInsets()), footer: FooterView()) {
                DetailsRowView(title: "details_row_title_cid".localized,
                               subtitle: viewModel.cardCid)
                DetailsRowView(title: "details_row_title_issuer".localized,
                               subtitle: viewModel.cardModel.cardInfo.card.cardData?.issuerName ?? " ")
                if viewModel.hasWallet, !viewModel.isTwinCard,
                   viewModel.cardModel.cardInfo.card.walletSignedHashes != nil {
                    DetailsRowView(title: "details_row_title_signed_hashes".localized,
                                   subtitle: String(format: "details_row_subtitle_signed_hashes_format".localized,
                                                    viewModel.cardModel.cardInfo.card.walletSignedHashes!.description))
                }
            }
            
            Section(header: HeaderView(text: "details_section_title_settings".localized), footer: FooterView()) {
                NavigationLink(destination: CurrencySelectView(viewModel: viewModel.assembly.makeCurrencySelectViewModel()),
                               tag: "currency", selection: $selection) {
                    DetailsRowView(title: "details_row_title_currency".localized,
                                   subtitle: viewModel.ratesService.selectedCurrencyCode)
                    
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
                
                NavigationLink(destination: DisclaimerView(viewModel: viewModel.assembly.makeDisclaimerViewModel(with: .read))
                                .background(Color.tangemTapBgGray.edgesIgnoringSafeArea(.all)),
                               tag: "disclaimer", selection: $selection) {
                    DetailsRowView(title: "disclaimer_title".localized,
                                   subtitle: "")
                    
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
                
                if let cardTouURL = viewModel.cardTouURL {
                    NavigationLink(destination: WebViewContainer(url: cardTouURL, title: "details_row_title_card_tou")
                                    .background(Color.tangemTapBgGray.edgesIgnoringSafeArea(.all)),
                                   tag: "card_tou", selection: $selection) {
                        DetailsRowView(title: "details_row_title_card_tou".localized,
                                       subtitle: "")
                        
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
                }
            }
            
            Section(header: HeaderView(text: "details_section_title_card".localized),
                    footer: footerView) {
                
                NavigationLink(destination: SecurityManagementView(viewModel:
                                                                    viewModel.assembly.makeSecurityManagementViewModel(with: viewModel.cardModel)),
                               tag: "secManagement", selection: $selection) {
                    DetailsRowView(title: "details_row_title_manage_security".localized,
                                   subtitle: viewModel.cardModel.currentSecOption.title)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
                .disabled(!viewModel.cardModel.canManageSecurity)
                
                if viewModel.isTwinCard {
                    NavigationLink(destination: TwinCardOnboardingView(viewModel: viewModel.assembly.makeTwinCardWarningViewModel(isRecreating: true)),
                                   isActive: $navigation.detailsToTwinsRecreateWarning){
                        DetailsRowView(title: "details_row_title_twins_recreate".localized, subtitle: "")
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
                    .disabled(!viewModel.cardModel.canRecreateTwinCard)
                    
                } else {
                    NavigationLink(destination: CardOperationView(title: "details_row_title_erase_wallet".localized,
                                                                  buttonTitle: "details_row_title_erase_wallet",
                                                                  alert: "details_erase_wallet_warning".localized,
                                                                  actionButtonPressed: {self.viewModel.cardModel.purgeWallet(completion: $0)}
                    ),
                    tag: "cardOp", selection: $selection) {
                        DetailsRowView(title: "details_row_title_erase_wallet".localized, subtitle: "")
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
                    .disabled(!viewModel.cardModel.canPurgeWallet)
                }
            }
            
            if let wallet = viewModel.cardModel.walletModel, wallet.canManageTokens {
                Section(header: HeaderView(text: "details_section_title_blockchain".localized), footer: FooterView(text: "", additionalBottomPadding: 40)) {
                    NavigationLink(
                        destination: ManageTokensView(viewModel: viewModel.assembly.makeManageTokensViewModel(with: wallet)),
                        tag: "manageTokens",
                        selection: $selection,
                        label: {
                            DetailsRowView(title: "details_row_title_manage_tokens".localized, subtitle: "")
                        })
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
                }
            }
            
            
            Section(header: Color.tangemTapBgGray
                        .listRowInsets(EdgeInsets())) {
                EmptyView()
            }
        }
        .padding(.top, 16)
        .background(Color.tangemTapBgGray.edgesIgnoringSafeArea(.all))
        .navigationBarTitle("details_title", displayMode: .inline)
        .navigationBarBackButtonHidden(false)
        .navigationBarHidden(false)
        .onDisappear {
            if #available(iOS 14.3, *) {
                self.selection = nil
            }
        }
    }
    
    var footerView: AnyView {
        if let purgeWalletProhibitedDescription = viewModel.cardModel.purgeWalletProhibitedDescription {
            return  FooterView(text: purgeWalletProhibitedDescription).toAnyView()
        }
        
        return FooterView().toAnyView()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DetailsView(viewModel: Assembly.previewAssembly.makeDetailsViewModel(with: CardViewModel.previewCardViewModel))
                .environmentObject(Assembly.previewAssembly.navigationCoordinator)
                .previewGroup(devices: [.iPhone8Plus])
        }
        .navigationViewStyle(StackNavigationViewStyle())
        
    }
}
