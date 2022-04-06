//
//  TokenListView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import BlockchainSdk
import Combine
import AlertToast

struct TokenListView: View {
    @ObservedObject var viewModel: TokenListViewModel
    @EnvironmentObject var navigation: NavigationCoordinator
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            navigationLinks
            
            HStack {
                Text(viewModel.titleKey)
                    .font(Font.system(size: 30, weight: .bold, design: .default))
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                
                Spacer()
                
                if !viewModel.isReadonlyMode {
                    Button(action: viewModel.showCustomTokenView) {
                        ZStack {
                            Circle().fill(Color.tangemGreen2)
                            
                            Image(systemName: "plus")
                                .foregroundColor(.white)
                                .font(.system(size: 13, weight: .bold, design: .default))
                        }
                        .frame(width: 26, height: 26)
                        .padding(16)
                    }
                }
            }
            
            SearchBar(text: $viewModel.enteredSearchText.value, placeholder: "common_search".localized)
                .background(Color.white)
                .padding(.horizontal, 8)
            
            if viewModel.isLoading {
                Spacer()
                ActivityIndicatorView(color: .gray)
                Spacer()
            } else {
                List {
                    
                    if viewModel.shouldShowAlert {
                        Text("alert_manage_tokens_addresses_message")
                            .font(.system(size: 13, weight: .medium, design: .default))
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color(hex: "#848488"))
                            .cornerRadius(10)
                            .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                    
                    ForEach(viewModel.filteredData) {
                        CurrencyView(model: $0)
                            .buttonStyle(PlainButtonStyle()) //fix ios13 list item selection
                    }
                }
                .listStyle(PlainListStyle())
            }
            
            if !viewModel.isReadonlyMode {
                TangemButton(title: "common_save_changes", action: viewModel.saveChanges)
                    .buttonStyle(TangemButtonStyle(colorStyle: .black,
                                                   layout: .flexibleWidth,
                                                   isDisabled: viewModel.isSaveDisabled,
                                                   isLoading: viewModel.isSaving))
                    .padding([.leading, .trailing, .top], 16)
                    .padding(.bottom, 8)
                    .ignoresKeyboard()
            }
        }
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDissapear() }
        .alert(item: $viewModel.error, content: { $0.alert })
        .background(Color.clear)
        .navigationBarHidden(true)
        .navigationBarTitle("")
        .toast(isPresenting: $viewModel.showToast) {
            AlertToast(type: .complete(Color.tangemGreen), title: "contract_address_copied_message".localized)
        }
    }
    
    private var navigationLinks: some View {
        NavigationLink(isActive: $navigation.mainToCustomToken) {
            AddCustomTokenView(viewModel: viewModel.assembly.makeAddCustomTokenModel())
                .environmentObject(navigation)
        } label: {
            EmptyView()
        }
        .hidden()
    }
}


struct AddNewTokensView_Previews: PreviewProvider {
    static let assembly = Assembly.previewAssembly
    
    static var previews: some View {
        TokenListView(viewModel: assembly.makeTokenListViewModel(mode: .add(cardModel: assembly.previewCardViewModel)))
            .environmentObject(assembly.services.navigationCoordinator)
    }
}
