//
//  ManageTokensView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemSdk
import BlockchainSdk

struct ManageTokensView: View {
    
    @ObservedObject var viewModel: ManageTokensViewModel
    @EnvironmentObject var navigation: NavigationCoordinator
    
    @State var tokenToRemove: TokenBalanceViewModel?
    
    var body: some View {
        ZStack {
            Color.tangemTapBgGray.edgesIgnoringSafeArea(.all)
            if viewModel.walletModel.tokensViewModels.count == 0 {
                VStack(spacing: 29) {
                    Image("no_tokens")
                    Text("manage_tokens_no_tokens")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.tangemTapGrayDark6)
                }
                .offset(x: 0, y: -70)
            } else {
                List {
                    Section(header: HeaderView(text: "manage_tokens_section_title_added_tokens".localized, additionalTopPadding: 14)) {
                        ForEach(viewModel.walletModel.tokensViewModels, id: \.id) { item in
                            AddedManagedTokenView(token: item, removeTokenAction: {
                                tokenToRemove = item
                            })
                        }
                        
                        .frame(height: 64)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    }
                }
                .alert(item: $tokenToRemove, content: { (token) -> Alert in
                    Alert(title: Text(String(format: "manage_tokens_alert_remove_token_title".localized, token.name)),
                          message: Text("manage_tokens_alert_remove_token_message".localized),
                          primaryButton: Alert.Button.destructive(Text("common_remove"), action: {
                            withAnimation {
                                viewModel.removeToken(token)
                            }
                          }),
                          secondaryButton: Alert.Button.cancel())
                })
            }
        }
        .background(NavigationLink(destination: AddNewTokensView(viewModel: viewModel.addTokensModel), isActive: $navigation.manageTokensToAddNewTokens))
        .navigationBarTitle("details_row_title_manage_tokens", displayMode: .inline)
        .navigationBarItems(trailing: Button(action: {
            navigation.manageTokensToAddNewTokens.toggle()
        }, label: {
            Image(systemName: "plus")
        })
        .foregroundColor(Color.tangemTapBlue2)
        .frame(minWidth: 44, minHeight: 44))
    }
}

struct ManageTokenView_Previews: PreviewProvider {
    
    static let assembly = Assembly.previewAssembly
    static let walletModel = assembly.makeWalletModel(from: assembly.cardsRepository.lastScanResult.cardModel!.cardInfo)
    
    static var previews: some View {
        NavigationView(content: {
            ManageTokensView(viewModel: assembly.makeManageTokensViewModel(with: walletModel!))
        })
        .navigationViewStyle(StackNavigationViewStyle())
        .environmentObject(assembly.navigationCoordinator)
    }
}
