//
//  AddCustomTokenView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct TextInputWithTitle: View {
    
    var title: String
    var placeholder: String
    var text: Binding<String>
    var keyboardType: UIKeyboardType
    var height: CGFloat = 60
    var backgroundColor: Color = .white
    
    @State var isResponder: Bool? = nil
    @State var buttonTapped: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Color.tangemTapGrayDark6)
            CustomTextField(text: text, isResponder: $isResponder, actionButtonTapped: $buttonTapped, handleKeyboard: true, keyboard: keyboardType, font: UIFont.systemFont(ofSize: 17, weight: .regular), placeholder: placeholder)
        }
        .onTapGesture {
            isResponder = true
        }
        .padding(.horizontal, 16)
        .frame(minHeight: height)
        .background(backgroundColor)
    }
}

struct AddCustomTokenView: View {
    
    @ObservedObject var viewModel: AddCustomTokenViewModel
    @EnvironmentObject var navigation: NavigationCoordinator
    
    var body: some View {
        VStack {
            VStack(spacing: 1) {
                TextInputWithTitle(title: "custom_token_name_input_title".localized, placeholder: "custom_token_name_input_placeholder".localized, text: $viewModel.name, keyboardType: .default)
                TextInputWithTitle(title: "custom_token_token_symbol_input_title".localized, placeholder: "custom_token_token_symbol_input_placeholder".localized, text: $viewModel.symbolName, keyboardType: .default)
                TextInputWithTitle(title: "custom_token_contract_address_input_title".localized, placeholder: "", text: $viewModel.contractAddress, keyboardType: .default)
                TextInputWithTitle(title: "custom_token_decimals_input_title".localized, placeholder: "0", text: $viewModel.decimals, keyboardType: .numberPad)
            }
            Spacer()
            HStack {
                Spacer()
                TangemLongButton(isLoading: viewModel.isSavingToken, title: "common_add", image: "plus", action: {
                    viewModel.createToken()
                })
                .buttonStyle(TangemButtonStyle(color: .black, isDisabled: false))
            }
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 16, trailing: 34))
        }
        .onDisappear(perform: {
            viewModel.onDisappear()
        })
        .onReceive(viewModel.$tokenSaved, perform: { tokenSaved in
            if tokenSaved {
                navigation.addNewTokensToCreateCustomToken = false
                navigation.manageTokensToAddNewTokens = false
            }
        })
        .alert(item: $viewModel.error, content: { $0.alert })
        .background(Color.tangemTapBgGray.edgesIgnoringSafeArea(.all))
        .navigationBarTitle("add_custom_token_title")
        .navigationBarHidden(false)
        .navigationBarBackButtonHidden(false)
    }
}

struct AddCustomTokenView_Previews: PreviewProvider {
    
    static let assembly = Assembly.previewAssembly
    static let walletModel = assembly.makeWalletModel(from: assembly.cardsRepository.lastScanResult.cardModel!.cardInfo)
    
    static var previews: some View {
        AddCustomTokenView(viewModel: Assembly.previewAssembly.makeAddCustomTokenViewModel(for: walletModel!))
    }
}
