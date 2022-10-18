//
//  AddCustomTokenView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct AddCustomTokenView: View {
    @ObservedObject var viewModel: AddCustomTokenViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                VStack(spacing: 1) {
                    TextInputWithTitle(title: "custom_token_contract_address_input_title".localized, placeholder: "0x0000000000000000000000000000000000000000", text: $viewModel.contractAddress, keyboardType: .default, isEnabled: true, isLoading: viewModel.isLoading)
                        .cornerRadius(10, corners: [.topLeft, .topRight])

                    PickerInputWithTitle(title: "custom_token_network_input_title".localized, model: $viewModel.blockchainsPicker)

                    TextInputWithTitle(title: "custom_token_name_input_title".localized, placeholder: "custom_token_name_input_placeholder".localized, text: $viewModel.name, keyboardType: .default, isEnabled: viewModel.canEnterTokenDetails, isLoading: false)

                    TextInputWithTitle(title: "custom_token_token_symbol_input_title".localized, placeholder: "custom_token_token_symbol_input_placeholder".localized, text: $viewModel.symbol, keyboardType: .default, isEnabled: viewModel.canEnterTokenDetails, isLoading: false)

                    TextInputWithTitle(title: "custom_token_decimals_input_title".localized, placeholder: "0", text: $viewModel.decimals, keyboardType: .numberPad, isEnabled: viewModel.canEnterTokenDetails, isLoading: false)
                        .cornerRadius(viewModel.showDerivationPaths ? 0 : 10, corners: [.bottomLeft, .bottomRight])

                    if viewModel.showDerivationPaths {
                        PickerInputWithTitle(title: "custom_token_derivation_path_input_title".localized, model: $viewModel.derivationsPicker)
                            .cornerRadius(10, corners: [.bottomLeft, .bottomRight])
                    }
                }

                WarningListView(warnings: viewModel.warningContainer, warningButtonAction: { _, _, _ in })

                TangemButton(title: "custom_token_add_token", systemImage: "plus", action: viewModel.createToken)
                    .buttonStyle(TangemButtonStyle(colorStyle: .black, layout: .flexibleWidth, isDisabled: viewModel.addButtonDisabled, isLoading: viewModel.isLoading))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color.tangemBgGray.edgesIgnoringSafeArea(.all))
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
        .alert(item: $viewModel.error, content: { $0.alert })
        .navigationBarTitle("add_custom_token_title", displayMode: .inline) // fix ios14 navbar overlap
    }
}

// [REDACTED_TODO_COMMENT]
fileprivate struct TextInputWithTitle: View {
    var title: String
    var placeholder: String
    var text: Binding<String>
    var keyboardType: UIKeyboardType
    var height: CGFloat = 60
    var backgroundColor: Color =  .white
    let isEnabled: Bool
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Color.tangemGrayDark6)

            HStack {
                CustomTextField(text: text, isResponder: .constant(nil), actionButtonTapped: .constant(false), handleKeyboard: true, keyboard: keyboardType, textColor: isEnabled ? UIColor.tangemGrayDark4 : .lightGray, font: UIFont.systemFont(ofSize: 17, weight: .regular), placeholder: placeholder, isEnabled: isEnabled)

                if isLoading {
                    ActivityIndicatorView(isAnimating: true, color: .tangemGrayDark)
                }
            }
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
    @Binding var model: PickerModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Color.tangemGrayDark6)

            HStack {
                Picker("", selection: $model.selection) {
                    ForEach(model.items, id: \.1) { value in
                        Text(value.0)
                            .minimumScaleFactor(0.7)
                            .tag(value.1)
                    }
                }
                .id(model.id)
                .modifier(PickerStyleModifier())
                .disabled(!model.isEnabled)
                .modifier(PickerAlignmentModifier())

                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(backgroundColor)
    }
}

// MARK: - Modifiers

fileprivate struct PickerAlignmentModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16, *) {
            content
                .padding(.leading, -12)
        } else {
            content
        }
    }
}

fileprivate struct PickerStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 15, *) {
            content
                .pickerStyle(.menu)
        } else {
            content
                .pickerStyle(.wheel)
        }
    }
}

struct AddCustomTokenView_Previews: PreviewProvider {
    static var previews: some View {
        AddCustomTokenView(viewModel: .init(cardModel: PreviewCard.tangemWalletEmpty.cardModel, coordinator: TokenListCoordinator()))
    }
}
