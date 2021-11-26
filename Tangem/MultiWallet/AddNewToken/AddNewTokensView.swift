//
//  AddNewTokensView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import BlockchainSdk
import Combine

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
                    .foregroundColor(.tangemGrayDark6)
                Text(symbol)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.tangemGrayDark)
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
            
            SearchBar(text:$viewModel.enteredSearchText, placeholder: "common_search".localized)
                .background(Color.white)
                .padding(.horizontal, 8)
            
            List {
                Section(header: HeaderView(text: "add_token_section_title_blockchains".localized, collapsible: false)) {
                    ForEach(viewModel.getBlockchains(filter: searchText)) { tokenView(for: $0) }
                }
                
                if !viewModel.availableEthereumTokens.isEmpty {
                    Section(header: HeaderView(text: "add_token_section_title_popular_tokens".localized,
                                               collapsible: true,
                                               isExpanded: viewModel.isEthTokensVisible,
                                               onCollapseAction: { withAnimation { viewModel.isEthTokensVisible.toggle() }})) {
                        ForEach(viewModel.getVisibleEthTokens(filter: searchText)) { tokenView(for: $0) }
                    }
                }
                
                if !viewModel.availableBnbTokens.isEmpty {
                    Section(header: HeaderView(text: "add_token_section_title_binance_tokens".localized,
                                               collapsible: true,
                                               isExpanded: viewModel.isBnbTokensVisible,
                                               onCollapseAction: { withAnimation { viewModel.isBnbTokensVisible.toggle() }})) {
                        ForEach(viewModel.getVisibleBnbTokens(filter: searchText)) { tokenView(for: $0) }
                    }
                }
                
                if !viewModel.availableBscTokens.isEmpty {
                    Section(header: HeaderView(text: "add_token_section_title_binance_smart_chain_tokens".localized, collapsible: true, isExpanded: viewModel.isBscTokensVisible, onCollapseAction: { withAnimation { viewModel.isBscTokensVisible.toggle() }})) {
                         ForEach(viewModel.getVisibleBscTokens(filter: searchText)) { tokenView(for: $0) }
                    }
                }
                    
                Color.white
                    .frame(width: 50, height: 150, alignment: .center)
                    .listRowInsets(EdgeInsets())
            }
            
            TangemButton(title: "common_save_changes", action: viewModel.saveChanges)
                .buttonStyle(TangemButtonStyle(colorStyle: .black,
                                               layout: .flexibleWidth,
                                               isLoading: viewModel.isLoading))
        }
        .onReceive(viewModel.$enteredSearchText
                    .dropFirst()
                    .debounce(for: 0.5, scheduler: DispatchQueue.main), perform: { value in
            searchText = value
        })
        .onDisappear(perform: {
            if navigation.addNewTokensToCreateCustomToken { return }
            
            viewModel.clear()
        })
        .alert(item: $viewModel.error, content: { $0.alert })
        .background(Color.white)
    }
    
    private func tokenView(for item: TokenItem) -> some View {
        TokenView(isTestnet: viewModel.isTestnet,
                  isAdded: viewModel.isAdded(item),
                  isLoading: false,
                  name: item.name,
                  symbol: item.symbol,
                  tokenItem: item,
                  addAction: { viewModel.add(item) },
                  removeAction: {})
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
                    .foregroundColor(.tangemGrayDark)
                    .padding(.leading, 20)
                
                Spacer()
                if collapsible {
                    Image(systemName: "chevron.down")
                        .rotationEffect(isExpanded ? .zero : Angle(degrees: -90))
                        .padding(.trailing, 16)
                        .foregroundColor(.tangemGrayDark)
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
