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

struct AddNewTokensView: View {
    @ObservedObject var viewModel: AddNewTokensViewModel
    @EnvironmentObject var navigation: NavigationCoordinator
    @Environment(\.presentationMode) var presentationMode
    
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
                ForEach(viewModel.data) { section in
                    Section(header: HeaderView(text: section.name,
                                               collapsible: section.collapsible,
                                               isExpanded: section.expanded)
                                .onTapGesture(perform: { withAnimation { viewModel.onCollapse(section) } })) {
                        if section.expanded {
                            ForEach(section.searchResults(viewModel.searchText)) { tokenModel in
                                TokenView(token: tokenModel)
                            }
                        }
                    }
                }
            }
            
            TangemButton(title: "common_save_changes", action: viewModel.saveChanges)
                .buttonStyle(TangemButtonStyle(colorStyle: .black,
                                               layout: .flexibleWidth,
                                               isDisabled: viewModel.pendingTokenItems.isEmpty,
                                               isLoading: viewModel.isLoading))
                .padding([.leading, .trailing, .top], 16)
                .padding(.bottom, 8)
        }
        .ignoresKeyboard()
        .onReceive(viewModel.$enteredSearchText
                    .dropFirst()
                    .debounce(for: 0.5, scheduler: DispatchQueue.main), perform: { value in
            viewModel.searchText = value
        })
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDissapear() }
        .alert(item: $viewModel.error, content: { $0.alert })
        .background(Color.white)
    }
}

fileprivate struct HeaderView: View {
    var text: String
    var additionalTopPadding: CGFloat = 0
    var collapsible: Bool
    var isExpanded: Bool = true
    
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
    }
}

fileprivate struct TokenView: View {
    let token: TokenModel
    
    private var buttonTitle: LocalizedStringKey {
        token.isAdded ? "common_added" : "common_add"
    }
    
    private var buttonStyle: TangemButtonStyle {
        TangemButtonStyle(colorStyle: token.isAdded || !token.canAdd ? .gray : .green,
                          layout: .thinHorizontal,
                          isDisabled: token.isAdded || !token.canAdd )
    }
    
    var body: some View {
        HStack {
            TokenIconView(token: token.tokenItem, size: CGSize(width: 80, height: 80))
                .saturation(token.tokenItem.blockchain.isTestnet ? 0 : 1.0)
                .frame(width: 40, height: 40, alignment: .center)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(token.tokenItem.name)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.tangemGrayDark6)
                Text(token.tokenItem.symbol)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.tangemGrayDark)
            }
            Spacer()
            TangemButton(title: buttonTitle, action: token.tap)
                .buttonStyle(buttonStyle)
        }
        .padding(.vertical, 8)
    }
}

struct AddNewTokensView_Previews: PreviewProvider {
    static let assembly = Assembly.previewAssembly
    
    static var previews: some View {
        AddNewTokensView(viewModel: assembly.makeAddTokensViewModel(for: assembly.previewCardViewModel))
            .environmentObject(assembly.services.navigationCoordinator)
    }
}
