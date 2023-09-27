//
//  AddCustomTokenView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct AddCustomTokenView: View {
    @ObservedObject private var viewModel: AddCustomTokenViewModel

    @Environment(\.displayScale) private var displayScale

    init(viewModel: AddCustomTokenViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Text(Localization.customTokenSubtitle)
                    .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 22)

                VStack(spacing: 14) {
                    Button {
                        viewModel.openNetworkSelector()
                    } label: {
                        ItemSelectorRow(title: Localization.customTokenNetworkInputTitle, selectedItem: viewModel.selectedBlockchainName)
                    }
                    .background(Colors.Background.action)
                    .cornerRadiusContinuous(12)

                    if viewModel.canEnterTokenDetails {
                        VStack(spacing: 0) {
                            TextInputWithTitle(title: Localization.customTokenContractAddressInputTitle, placeholder: "0x0000000000000000000000000000000000000000", text: $viewModel.contractAddress, keyboardType: .default, isEnabled: true, isLoading: false, error: viewModel.contractAddressError)

                            separator

                            TextInputWithTitle(title: Localization.customTokenNameInputTitle, placeholder: Localization.customTokenNameInputPlaceholder, text: $viewModel.name, keyboardType: .default, isEnabled: viewModel.canEnterTokenDetails, isLoading: viewModel.isLoading)

                            separator

                            TextInputWithTitle(title: Localization.customTokenTokenSymbolInputTitleOld, placeholder: Localization.customTokenTokenSymbolInputPlaceholder, text: $viewModel.symbol, keyboardType: .default, isEnabled: viewModel.canEnterTokenDetails, isLoading: viewModel.isLoading)

                            separator

                            TextInputWithTitle(title: Localization.customTokenDecimalsInputTitle, placeholder: "0", text: $viewModel.decimals, keyboardType: .numberPad, isEnabled: viewModel.canEnterTokenDetails, isLoading: viewModel.isLoading)
                        }
                        .background(Colors.Background.action)
                        .cornerRadiusContinuous(12)
                    }

                    if viewModel.showDerivationPaths {
                        Button {
                            viewModel.openNetworkSelector()
                        } label: {
                            ItemSelectorRow(title: Localization.customTokenDerivationPath, selectedItem: "Default")
                        }
                        .background(Colors.Background.action)
                        .cornerRadiusContinuous(12)
                    }

                    if viewModel.showDerivationPaths {
                        VStack(spacing: 0) {
                            PickerInputWithTitle(title: Localization.customTokenDerivationPathInputTitle, model: $viewModel.derivationsPicker)

                            if viewModel.showCustomDerivationPath {
                                TextInputWithTitle(title: Localization.customTokenCustomDerivation, placeholder: "m/44'/0'/0'/0/0", text: $viewModel.customDerivationPath, keyboardType: .default, isEnabled: true, isLoading: false)
                            }
                        }
                    }

                    MainButton(
                        title: Localization.customTokenAddToken,
                        icon: .leading(Assets.plusMini),
                        isLoading: viewModel.isLoading,
                        isDisabled: viewModel.addButtonDisabled,
                        action: viewModel.createToken
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Colors.Background.tertiary.edgesIgnoringSafeArea(.all))
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
        .alert(item: $viewModel.error, content: { $0.alert })
        .navigationBarTitle(Text(Localization.addCustomTokenTitle), displayMode: .inline)
    }

    private var separator: some View {
        Separator(height: 1 / displayScale, padding: 0, color: Colors.Stroke.primary)
            .padding(.leading, 16)
    }
}

private struct ItemSelectorRow: View {
    let title: String
    let selectedItem: String?

    var body: some View {
        HStack(spacing: 17) {
            Text(title)
                .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let selectedItem {
                Text(selectedItem)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
            }

            Assets.chevron.image
                .renderingMode(.template)
                .foregroundColor(Colors.Icon.informative)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// [REDACTED_TODO_COMMENT]
private struct TextInputWithTitle: View {
    var title: String
    var placeholder: String
    var text: Binding<String>
    var keyboardType: UIKeyboardType
    var height: CGFloat = 60
    let isEnabled: Bool
    let isLoading: Bool
    var error: Error?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let error {
                Text(error.localizedDescription)
                    .style(Fonts.Regular.caption1, color: Colors.Text.warning)
            } else {
                Text(title)
                    .style(Fonts.Regular.caption1, color: Colors.Text.secondary)
            }

            HStack(spacing: 0) {
                CustomTextField(text: text, isResponder: .constant(nil), actionButtonTapped: .constant(false), handleKeyboard: true, keyboard: keyboardType, textColor: isEnabled ? UIColor.tangemGrayDark4 : .lightGray, font: UIFont.systemFont(ofSize: 17, weight: .regular), placeholder: placeholder, isEnabled: isEnabled)
                    .opacity(isLoading ? 0 : 1)
                    .overlay(skeleton, alignment: .leading)

                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var skeleton: some View {
        if isLoading {
            SkeletonView()
                .frame(size: CGSize(width: 90, height: 12))
                .cornerRadiusContinuous(3)
        }
    }
}

private struct PickerInputWithTitle: View {
    var title: String
    var height: CGFloat = 60
    @Binding var model: LegacyPickerModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .style(Fonts.Regular.caption1, color: Colors.Text.secondary)

            HStack {
                Picker("", selection: $model.selection) {
                    ForEach(model.items, id: \.1) { value in
                        Text(value.0)
                            .minimumScaleFactor(0.7)
                            .tag(value.1)
                    }
                }
                .id(model.id)
                .accentColor(Colors.Button.positive)
                .modifier(PickerStyleModifier())
                .disabled(!model.isEnabled)
                .modifier(PickerAlignmentModifier())

                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Modifiers

private struct PickerAlignmentModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16, *) {
            content
                .padding(.leading, -12)
        } else {
            content
        }
    }
}

private struct PickerStyleModifier: ViewModifier {
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

struct AddCustomTokenView_Preview: PreviewProvider {
    static let settings = LegacyManageTokensSettings(
        supportedBlockchains: SupportedBlockchains.all.filter { !$0.isTestnet },
        hdWalletsSupported: true,
        longHashesSupported: true,
        derivationStyle: .v1,
        shouldShowLegacyDerivationAlert: true,
        existingCurves: [.ed25519, .secp256k1]
    )

    static let userTokensManager: UserTokensManager = {
        let fakeUserTokenListManager = FakeUserTokenListManager()
        return FakeUserTokensManager(
            derivationManager: FakeDerivationManager(pendingDerivationsCount: 5),
            userTokenListManager: fakeUserTokenListManager
        )
    }()

    static let viewModel = AddCustomTokenViewModel(
        settings: settings,
        userTokensManager: userTokensManager,
        coordinator: AddCustomTokenCoordinator()
    )

    static var previews: some View {
        NavigationView {
            AddCustomTokenView(viewModel: viewModel)
        }
    }
}
