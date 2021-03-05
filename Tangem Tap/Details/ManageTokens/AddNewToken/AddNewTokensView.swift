//
//  AddNewTokensView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import BlockchainSdk

//enum TokenImage {
//    case image(String)
//    case color(Color, String)
//    
//    var view: some View {
//        switch self {
//        case .image(let name):
//            return Image(name)
//        case .color(let color, let name):
//            return Circle()
//        }
//    }
//}

struct PresetTokenView: View {
    var isAdded: Bool
    var isLoading: Bool
    var name: String
    var symbol: String
    var walletItem: WalletItem
    var addAction: () -> Void
    var removeAction: () -> Void
    
    var body: some View {
        HStack {
            switch walletItem {
            case .token(let token):
                CircleImageView(name: token.name, color: token.color)
            case .blockchain(let blockchain):
                if let image = blockchain.imageName {
                    Image(image)
                } else {
                    CircleImageView(name: blockchain.displayName,
                                    color: Color.tangemTapGrayLight4)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(name)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.tangemTapGrayDark6)
                Text(symbol)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.tangemTapGrayDark)
            }
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
                        PresetTokenView(isAdded: viewModel.isAdded(blockchain),
                                        isLoading: false,
                                        name: blockchain.displayName,
                                        symbol: blockchain.currencySymbol,
                                        walletItem: .blockchain(blockchain),
                                        addAction: {
                            viewModel.addBlockchain(blockchain)
                        }, removeAction: {
                            viewModel.removeBlockchain(blockchain)
                        })                    }
                }
                
                Section(header: HeaderView(text: "add_token_section_title_popular_tokens".localized)) {
                    ForEach(viewModel.availableTokens.filter {
                                searchText.isEmpty || $0.name.lowercased().contains(searchText.lowercased()) || $0.symbol.lowercased().contains(searchText.lowercased()) }) { token in
                        PresetTokenView(isAdded: viewModel.isAdded(token),
                                        isLoading: viewModel.pendingTokensUpdate.contains(token), name: token.name,
                                        symbol: token.symbol,
                                        walletItem: .token(token),
                                        addAction: {
                            viewModel.addTokenToList(token: token)
                        }, removeAction: {
                            viewModel.removeTokenFromList(token: token)
                        })
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
            .environmentObject(assembly.navigationCoordinator)
    }
}
