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
    let isTestnet: Bool
    
    var isAdded: Bool
    var isLoading: Bool
    var name: String
    var symbol: String
    var tokenItem: TokenItem
    var addAction: () -> Void
    var removeAction: () -> Void
    
    private var buttonTitle: LocalizedStringKey {
        isAdded ? "common_added" : "common_add"
    }
    
    private var buttonAction: () -> Void {
        isAdded ? removeAction : addAction
    }
    
    private var buttonStyle: TangemButtonStyle {
        TangemButtonStyle(colorStyle: isAdded ? .gray : .green,
                          layout: .thinHorizontal,
                          isDisabled: isAdded,
                          isLoading: isLoading)
    }
    
    var body: some View {
        HStack {
            TokenIconView(token: tokenItem)
                .saturation(isTestnet ? 0 : 1.0)
                .frame(width: 40, height: 40, alignment: .center)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(name)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.tangemTapGrayDark6)
                Text(symbol)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.tangemTapGrayDark)
            }
            Spacer()
            TangemButton(title: buttonTitle, action: buttonAction)
                .buttonStyle(buttonStyle)
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
                Section(header: HeaderView(text: "add_token_section_title_blockchains".localized, collapsible: false)) {
                    ForEach(viewModel.availableBlockchains.filter {
                        searchText.isEmpty || $0.displayName.lowercased().contains(searchText.lowercased())
                            || $0.currencySymbol.lowercased().contains(searchText.lowercased())
                    }) { blockchain in
                        TokenView(isTestnet: viewModel.isTestnet,
                                  isAdded: viewModel.isAdded(blockchain),
                                  isLoading: false,
                                  name: blockchain.displayName,
                                  symbol: blockchain.currencySymbol,
                                  tokenItem: .blockchain(blockchain),
                                  addAction: {
                                    viewModel.addBlockchain(blockchain)
                                  }, removeAction: {})}
                }
                
                if viewModel.availableEthereumTokens.count > 0 {
                    Section(header: HeaderView(text: "add_token_section_title_popular_tokens".localized, collapsible: true, isExpanded: viewModel.isEthTokensVisible, onCollapseAction: {
                        withAnimation {
                            viewModel.isEthTokensVisible.toggle()
                        }
                    })) {
                        ForEach(viewModel.visibleEthTokens.filter {
                                    searchText.isEmpty || $0.name.lowercased().contains(searchText.lowercased()) || $0.symbol.lowercased().contains(searchText.lowercased()) }) { token in
                            TokenView(isTestnet: viewModel.isTestnet,
                                      isAdded: viewModel.isAdded(token),
                                      isLoading: viewModel.pendingTokensUpdate.contains(token), name: token.name,
                                      symbol: token.symbol,
                                      tokenItem: .token(token),
                                      addAction: {
                                        viewModel.addTokenToList(token: token, blockchain: .ethereum(testnet: viewModel.isTestnet))
                                      }, removeAction: { })
                        }
                    }
                }
                
                if viewModel.availableBnbTokens.count > 0 {
                    Section(header: HeaderView(text: "add_token_section_title_binance_tokens".localized, collapsible: true, isExpanded: viewModel.isBnbTokensVisible, onCollapseAction: {
                        withAnimation {
                            viewModel.isBnbTokensVisible.toggle()
                        }
                    })) {
                        ForEach(viewModel.visibleBnbTokens.filter {
                                    searchText.isEmpty || $0.name.lowercased().contains(searchText.lowercased()) || $0.symbol.lowercased().contains(searchText.lowercased()) }) { token in
                            TokenView(isTestnet: viewModel.isTestnet,
                                      isAdded: viewModel.isAdded(token),
                                      isLoading: viewModel.pendingTokensUpdate.contains(token), name: token.name,
                                      symbol: token.symbol,
                                      tokenItem: .token(token),
                                      addAction: {
                                        viewModel.addTokenToList(token: token, blockchain: .binance(testnet: viewModel.isTestnet))
                                      }, removeAction: { })
                        }
                    }
                }
                
                if viewModel.availableBscTokens.count > 0 {
                    Section(header: HeaderView(text: "add_token_section_title_binance_smart_chain_tokens".localized, collapsible: true, isExpanded: viewModel.isBscTokensVisible, onCollapseAction: {
                        withAnimation {
                            viewModel.isBscTokensVisible.toggle()
                        }
                    })) {
                        ForEach(viewModel.visibleBscTokens.filter {
                                    searchText.isEmpty || $0.name.lowercased().contains(searchText.lowercased()) || $0.symbol.lowercased().contains(searchText.lowercased()) }) { token in
                            TokenView(isTestnet: viewModel.isTestnet,
                                      isAdded: viewModel.isAdded(token),
                                      isLoading: viewModel.pendingTokensUpdate.contains(token), name: token.name,
                                      symbol: token.symbol,
                                      tokenItem: .token(token),
                                      addAction: {
                                        viewModel.addTokenToList(token: token, blockchain: .bsc(testnet: viewModel.isTestnet))
                                      }, removeAction: { })
                        }
                    }
                }
                Color.white
                    .frame(width: 50, height: 150, alignment: .center)
                    .listRowInsets(EdgeInsets())
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
        var collapsible: Bool
        var isExpanded: Bool = true
        var onCollapseAction: (() -> Void)?
        
        var body: some View {
            HStack {
                Text(text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.tangemTapGrayDark)
                    .padding(.leading, 20)
                
                Spacer()
                if collapsible {
                    Image(systemName: "chevron.down")
                        .rotationEffect(isExpanded ? .zero : Angle(degrees: -90))
                        .padding(.trailing, 16)
                        .foregroundColor(.tangemTapGrayDark)
                }
            }
            
            .padding(.top, 16)
            .padding(.vertical, 5)
            .padding(.top, additionalTopPadding)
            .background(Color.white)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .onTapGesture(perform: {
                onCollapseAction?()
            })
        }
    }
}


struct AddNewTokensView_Previews: PreviewProvider {
    static let assembly = Assembly.previewAssembly
    
    static var previews: some View {
        AddNewTokensView(viewModel: assembly.makeAddTokensViewModel(for: assembly.previewCardViewModel))
            .environmentObject(assembly.services.navigationCoordinator)
    }
}
