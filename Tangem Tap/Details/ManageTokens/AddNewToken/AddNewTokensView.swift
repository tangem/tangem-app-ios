//
//  AddNewTokensView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import BlockchainSdk

struct PresetTokenView: View {
    
    var isAdded: Bool
    var isLoading: Bool
    var token: Token
    var addAction: () -> Void
    var removeAction: () -> Void
    
    var body: some View {
        HStack {
            Text(token.name)
            Spacer()
            TangemButton(isLoading: isLoading, title: isAdded ? "common_remove" : "common_add", image: "", size: .thinHorizontal, action: isAdded ? removeAction : addAction)
                .buttonStyle(isAdded ?
                                TangemButtonStyle(color: .gray, isDisabled: false) :
                                TangemButtonStyle(color: .green, isDisabled: false))
        }
    }
    
}

struct AddNewTokensView: View {
    
    @ObservedObject var viewModel: AddNewTokensViewModel
    @EnvironmentObject var navigation: NavigationCoordinator
    @Environment(\.presentationMode) var presentationMode
    
    @State var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            SearchBar(text: $searchText, placeholder: "common_search".localized)
                .padding(.horizontal, 8)
                .background(Color.tangemTapBgGray)
            List {
                Section(header: HeaderView(text: "add_token_section_title_popular_tokens".localized)) {
                    ForEach(viewModel.availableTokens.filter {
                                searchText.isEmpty || $0.name.lowercased().contains(searchText.lowercased()) }) { token in
                        PresetTokenView(isAdded: viewModel.tokensToSave.contains(token), isLoading: viewModel.pendingTokensUpdate.contains(token), token: token, addAction: {
                            viewModel.addTokenToList(token: token)
                        }, removeAction: {
                            viewModel.removeTokenFromList(token: token)
                        })
                    }
                    .frame(height: 52)
                }
            }
        }
        .onDisappear(perform: {
            if navigation.addNewTokensToCreateCustomToken { return }
            
            viewModel.clear()
        })
        .onAppear(perform: {
            viewModel.onAppear()
        })
        .alert(item: $viewModel.error, content: { $0.alert })
        .background(Color.tangemTapBgGray)
        .navigationBarTitle("add_tokens_title")
        .navigationBarItems(
            trailing: Button("add_custom", action: {
                navigation.addNewTokensToCreateCustomToken = true
            })
            .font(.system(size: 17, weight: .medium))
            .foregroundColor(.tangemTapBlue2)
            .frame(minHeight: 44)
            .background(
                NavigationLink(destination: AddCustomTokenView(viewModel: viewModel.assembly.makeAddCustomTokenViewModel(for: viewModel.walletModel)), isActive: $navigation.addNewTokensToCreateCustomToken))
        )
    }
}

struct AddNewTokensView_Previews: PreviewProvider {
    
    static let assembly = Assembly.previewAssembly
    static let walletModel = assembly.makeWalletModel(from: assembly.cardsRepository.lastScanResult.cardModel!.cardInfo)
    
    static var previews: some View {
        NavigationView {
            AddNewTokensView(viewModel: assembly.makeAddTokensViewModel(for: walletModel!))
        }
    }
}
