//
//  AddNewTokensView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import BlockchainSdk

fileprivate struct TokenView: View {
    var isAdded: Bool
    var isLoading: Bool
    var name: String
    var symbol: String
    var tokenItem: TokenItem
    var addAction: () -> Void
    var removeAction: () -> Void
    
    var body: some View {
        HStack {
            tokenItem.imageView
            
            VStack(alignment: .leading, spacing: 6) {
                Text(name)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.tangemTapGrayDark6)
                Text(symbol)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.tangemTapGrayDark)
            }
            Spacer()
            TangemButton(isLoading: isLoading, title: isAdded ? "common_added" : "common_add", image: "", size: .thinHorizontal, action: isAdded ? removeAction : addAction)
                .buttonStyle(isAdded ?
                                TangemButtonStyle(color: .gray, isDisabled: true) :
                                TangemButtonStyle(color: .green, isDisabled: false))
                .disabled(isAdded)
        }
        .padding(.vertical, 8)
    }
    
}

struct AddNewTokensView: View {
    
    @ObservedObject var viewModel: AddNewTokensViewModel
    @EnvironmentObject var navigation: NavigationCoordinator
    @Environment(\.presentationMode) var presentationMode
    
    @State var searchText = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("add_tokens_title")
                .font(Font.system(size: 36, weight: .bold, design: .default))
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            
            SearchBar(text: $searchText, placeholder: "common_search".localized)
                .background(Color.white)
                .padding(.horizontal, 8)
            
            List {
                Section(header: HeaderView(text: "add_token_section_title_blockchains".localized)) {
                    ForEach(viewModel.availableBlockchains.filter {
                        searchText.isEmpty || $0.displayName.lowercased().contains(searchText.lowercased())
                            || $0.currencySymbol.lowercased().contains(searchText.lowercased())
                    }) { blockchain in
                        TokenView(isAdded: viewModel.isAdded(blockchain),
                                  isLoading: false,
                                  name: blockchain.displayName,
                                  symbol: blockchain.currencySymbol,
                                  tokenItem: .blockchain(blockchain),
                                  addAction: {
                                    viewModel.addBlockchain(blockchain)
                                  }, removeAction: {})}
                }
                
                Section(header: HeaderView(text: "add_token_section_title_popular_tokens".localized)) {
                    ForEach(viewModel.availableTokens.filter {
                                searchText.isEmpty || $0.name.lowercased().contains(searchText.lowercased()) || $0.symbol.lowercased().contains(searchText.lowercased()) }) { token in
                        TokenView(isAdded: viewModel.isAdded(token),
                                  isLoading: viewModel.pendingTokensUpdate.contains(token), name: token.name,
                                  symbol: token.symbol,
                                  tokenItem: .token(token),
                                  addAction: {
                                    viewModel.addTokenToList(token: token)
                                  }, removeAction: { })
                    }
                }
            }
        }
        .onDisappear(perform: {
            if navigation.addNewTokensToCreateCustomToken { return }
            
            viewModel.clear()
        })
        .alert(item: $viewModel.error, content: { $0.alert })
        .background(Color.white)
        //        .navigationBarItems(
        //            trailing: Button("add_custom", action: {
        //                navigation.addNewTokensToCreateCustomToken = true
        //            })
        //            .font(.system(size: 17, weight: .medium))
        //            .foregroundColor(.tangemTapBlue2)
        //            .frame(minHeight: 44)
        //            .background(
        //                NavigationLink(destination: AddCustomTokenView(viewModel: viewModel.assembly.makeAddCustomTokenViewModel(for: viewModel.cardModel.erc20TokenWalletModel)), isActive: $navigation.addNewTokensToCreateCustomToken))
        //        )
    }
}

extension AddNewTokensView {
    struct HeaderView: View {
        var text: String
        var additionalTopPadding: CGFloat = 0
        var body: some View {
            HStack {
                Text(text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.tangemTapGrayDark)
                    .padding(.top, 16)
                    .padding(.leading, 20)
                    .padding(.vertical, 5)
                Spacer()
            }
            .padding(.top, additionalTopPadding)
            .background(Color.white)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        }
    }
}


struct AddNewTokensView_Previews: PreviewProvider {
    static let assembly = Assembly.previewAssembly
    
    static var previews: some View {
        AddNewTokensView(viewModel: assembly.makeAddTokensViewModel(for: CardViewModel.previewCardViewModel))
            .environmentObject(assembly.services.navigationCoordinator)
    }
}
