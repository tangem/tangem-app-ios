//
//  AddCustomTokenView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

// [REDACTED_TODO_COMMENT]
fileprivate struct TextInputWithTitle: View {
    var title: String
    var placeholder: String
    var text: Binding<String>
    var keyboardType: UIKeyboardType
    var height: CGFloat = 60
    var backgroundColor: Color = .white
    let isEnabled: Bool
    
    @State var isResponder: Bool? = nil
    @State var buttonTapped: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Color.tangemGrayDark6)
            CustomTextField(text: text, isResponder: $isResponder, actionButtonTapped: $buttonTapped, handleKeyboard: true, keyboard: keyboardType, textColor: isEnabled ? UIColor.tangemGrayDark4 : .gray, font: UIFont.systemFont(ofSize: 17, weight: .regular), placeholder: placeholder, isEnabled: isEnabled)
        }
        .onTapGesture {
            isResponder = true
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(backgroundColor)
    }
}

fileprivate struct PickerInputWithTitle: View {
    var title: String
    var height: CGFloat = 60
    var backgroundColor: Color = .white
    @Binding var value: String
    let values: [(String, String)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Color.tangemGrayDark6)
            
            HStack {
                Picker("", selection: $value) {
                    ForEach(values, id: \.1) { value in
                        Text(value.0)
                            .tag(value.1)
                    }
                }
                .modifier(PickerStyleModifier())
                
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(backgroundColor)
    }
}

fileprivate struct PickerStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 14, *) {
            content
                .pickerStyle(.menu)
        } else {
            content
                .pickerStyle(.wheel)
        }
    }
}


struct AddCustomTokenView: View {
    @ObservedObject var viewModel: AddCustomTokenViewModel
    @EnvironmentObject var navigation: NavigationCoordinator
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                HStack {
                    Text("add_custom_token_title".localized)
                        .font(Font.system(size: 36, weight: .bold, design: .default))
                        .padding(.vertical)
                    
                    Spacer()
                }
                
                VStack(spacing: 1) {
                    TextInputWithTitle(title: "custom_token_contract_address_input_title".localized, placeholder: "0x0000000000000000000000000000000000000000", text: $viewModel.contractAddress, keyboardType: .default, isEnabled: true)
                        .cornerRadius(10, corners: [.topLeft, .topRight])
                    
                    PickerInputWithTitle(title: "custom_token_network_input_title".localized, value: $viewModel.blockchainName, values: viewModel.blockchains)
                    
                    TextInputWithTitle(title: "custom_token_name_input_title".localized, placeholder: "custom_token_name_input_placeholder".localized, text: $viewModel.name, keyboardType: .default, isEnabled: viewModel.foundStandardToken == nil)
                    
                    TextInputWithTitle(title: "custom_token_token_symbol_input_title".localized, placeholder: "custom_token_token_symbol_input_placeholder".localized, text: $viewModel.symbol, keyboardType: .default, isEnabled: viewModel.foundStandardToken == nil)
                    
                    TextInputWithTitle(title: "custom_token_decimals_input_title".localized, placeholder: "0", text: $viewModel.decimals, keyboardType: .numberPad, isEnabled: viewModel.foundStandardToken == nil)
                    
                    PickerInputWithTitle(title: "custom_token_derivation_path_input_title".localized, value: $viewModel.derivationPath, values: viewModel.derivationPaths)
                        .cornerRadius(10, corners: [.bottomLeft, .bottomRight])
                }
                
                WarningListView(warnings: viewModel.warningContainer, warningButtonAction: { _,_,_ in })
                
                TangemButton(title: "common_add", systemImage: "plus", action: viewModel.createToken)
                    .buttonStyle(TangemButtonStyle(colorStyle: .black, layout: .flexibleWidth, isDisabled: viewModel.addButtonDisabled, isLoading: viewModel.isLoading))
            }
            .padding()
        }
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
        .alert(item: $viewModel.error, content: { $0.alert })
        .background(Color.tangemBgGray.edgesIgnoringSafeArea(.all))
    }
}

struct AddCustomTokenView_Previews: PreviewProvider {
    static let assembly = Assembly.previewAssembly
    
    static var previews: some View {
        AddCustomTokenView(viewModel: Assembly.previewAssembly.makeAddCustomTokenModel())
    }
}
