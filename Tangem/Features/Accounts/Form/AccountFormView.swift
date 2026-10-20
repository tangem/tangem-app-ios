//
//  AccountFormView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemUI
import TangemUIUtils
import TangemAccounts
import TangemLocalization

struct AccountFormView: View {
    // MARK: ViewModel

    @ObservedObject var viewModel: AccountFormViewModel

    // MARK: State

    @State private var contentHeight: CGFloat = 0
    @State private var containerHeight: CGFloat = 0

    @State private var buttonHeight: CGFloat = 0

    @State private var shouldShowShadow = false
    @FocusState private var isNameFocused: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            content

            overlayButtonView
        }
        .padding(.horizontal, 16)
        .background(DesignSystem.Color.bgPrimary)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(viewModel.title)
                    .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
            }
        }
        .withCloseButton(placement: .topBarTrailing, style: .icon) {
            viewModel.onClose()
        }
        .ignoresSafeArea(.keyboard)
        .alert(item: $viewModel.alert, content: { $0.alert })
        .modal(
            isPresented: $viewModel.isWalletSelectorPresented,
            contentLayout: .intrinsic,
            dragIndicator: .hidden,
            title: Localization.commonChooseWallet
        ) {
            if let walletSelector = viewModel.walletSelector {
                AccountSelectorView(viewModel: walletSelector, style: .modal)
                    .selectionCheckmarks()
            }
        }
        .submitLabel(.done)
        .onSubmit {
            // Do NOT access SwiftUI internal state (@State, @FocusState, @Binding, @StateObject, etc) inside the `onSubmit(of:_:)` closure.
            // This causes a memory leak as soon as the text field becomes the first responder.
            // See https://stackoverflow.com/questions/70510596 and https://stackoverflow.com/questions/78763987 for more details
            UIResponder.current?.resignFirstResponder()
        }
        .onAppear(perform: viewModel.onAppear)
        .focusOnAppear($isNameFocused, onlyOnce: true)
        .onChange(of: viewModel.selectedColor) { _ in
            isNameFocused = false
        }
        .onChange(of: viewModel.selectedIcon) { _ in
            isNameFocused = false
        }
    }

    private var content: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 8) {
                mainContent

                if let description = viewModel.description {
                    Text(description)
                        .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                        .transition(.opacity)
                }
            }
            .padding(.top, 12)
            .padding(.bottom, buttonHeight)
            .readGeometry(\.size.height) { height in
                contentHeight = height
            }
            .readContentOffset(inCoordinateSpace: .named(CoordinateSpaceName.scrollView)) { point in
                let contentMaxY = contentHeight - point.y
                shouldShowShadow = contentMaxY > containerHeight
            }
        }
        .coordinateSpace(name: CoordinateSpaceName.scrollView)
        .scrollDismissesKeyboard(.immediately)
        .scrollBounceBehavior(.basedOnSize)
        .readGeometry(\.size.height) { height in
            containerHeight = height
        }
        .animation(.default, value: viewModel.description)
    }

    private var overlayButtonView: some View {
        TangemUI.Button(label: viewModel.buttonTitle, accessibilityLabel: nil, action: viewModel.onMainButtonTap)
            .styleType(.primary)
            .size(.x12)
            .horizontalLayout(.infinity)
            .loading(.spinner(if: viewModel.isLoading))
            .disabled(viewModel.mainButtonDisabled)
            .accessibilityIdentifier(AccountsAccessibilityIdentifiers.accountFormMainButton)
            .padding(.vertical, 12)
            .background(alignment: .bottom) {
                Fade(position: .bottom)
                    .variant(.hard)
                    .padding(.horizontal, -16)
                    .ignoresSafeArea(edges: .bottom)
                    .hidden(!shouldShowShadow)
            }
            .readGeometry(\.size.height) { height in
                buttonHeight = height
            }
    }

    private var mainContent: some View {
        VStack(spacing: 8) {
            FormHeaderView(
                accountName: $viewModel.accountName,
                title: Localization.accountFormName,
                maxCharacters: viewModel.maxNameLength,
                placeholderText: viewModel.placeholder,
                accountIconViewData: viewModel.iconViewData,
                isFocused: $isNameFocused
            )

            AccountFormGridView(
                selectedItem: $viewModel.selectedColor,
                items: viewModel.colors,
                backgroundColor: DesignSystem.Color.bgSecondary,
                horizontalPadding: 16,
                cornerRadius: 24,
                content: { colorItem, isSelected in
                    makeColorItem(color: colorItem.color, isSelected: isSelected)
                }
            )

            AccountFormGridView(
                selectedItem: $viewModel.selectedIcon,
                items: viewModel.images,
                backgroundColor: DesignSystem.Color.bgSecondary,
                horizontalPadding: 16,
                cornerRadius: 24,
                content: { imageItem, isSelected in
                    makeIconItem(kind: imageItem.kind, isSelected: isSelected)
                }
            )

            if let wallet = viewModel.wallet {
                AccountFormWalletRow(wallet: wallet, action: viewModel.onWalletTap)
            }
        }
    }

    private func makeColorItem(color: Color, isSelected: Bool) -> some View {
        Circle()
            .fill(color)
            .frame(width: 40, height: 40)
            .overlay(makeSelectionRing(isSelected: isSelected, color: color))
    }

    private func makeIconItem(kind: GridItemImageKind, isSelected: Bool) -> some View {
        let iconColor = switch kind {
        case .image: isSelected ? DesignSystem.Color.iconPrimary : DesignSystem.Color.iconSecondary
        case .letter: DesignSystem.Color.iconBrand
        }

        let backgroundColor = switch kind {
        case .image: isSelected ? DesignSystem.Color.bgTransparentSecondary : DesignSystem.Color.bgTransparentPrimary
        case .letter: DesignSystem.Color.bgStatusInfoSubtle
        }

        return Circle()
            .fill(backgroundColor)
            .frame(width: 40, height: 40)
            .overlay(
                kind.imageType.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(iconColor)
            )
            .overlay(makeSelectionRing(isSelected: isSelected, color: DesignSystem.Color.borderTertiary))
    }

    private func makeSelectionRing(isSelected: Bool, color: Color) -> some View {
        Circle()
            .strokeBorder(color, lineWidth: isSelected ? 2 : 0)
            .frame(width: 48, height: 48)
    }
}

// MARK: - Wallet row

/// The wallet the account is created in, opens the wallet selection on tap when the wallet can be changed.
private struct AccountFormWalletRow: View {
    let wallet: AccountFormWallet
    let action: () -> Void

    @ScaledMetric private var thumbnailSize = Constants.thumbnailSize

    var body: some View {
        Row(title: Localization.commonWallet)
            .valueAccessory { walletValue }
            .if(wallet.isSelectable) { $0.onTap(action: action) }
            .background(DesignSystem.Color.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius, style: .continuous))
            .accessibilityIdentifier(AccountsAccessibilityIdentifiers.accountFormWalletRow)
    }

    private var walletValue: some View {
        HStack(spacing: Constants.valueSpacing) {
            walletThumbnail

            Text(wallet.name)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textSecondary)
                .lineLimit(1)

            if wallet.isSelectable {
                chevron
            }
        }
    }

    @ViewBuilder
    private var walletThumbnail: some View {
        if let thumbnailType = wallet.thumbnailType {
            MiniatureWalletView(type: thumbnailType)
                .frame(width: thumbnailSize, height: thumbnailSize)
        }
    }

    private var chevron: some View {
        DesignSystem.Icons.ChevronDown.regular16.image
            .renderingMode(.template)
            .foregroundStyle(DesignSystem.Color.iconSecondary)
    }

    private enum Constants {
        static let thumbnailSize: CGFloat = 20
        static let cornerRadius: CGFloat = 24
        static let valueSpacing: CGFloat = 4
    }
}

extension AccountFormView {
    private enum CoordinateSpaceName {
        private static let prefix = "AccountFormView.CoordinateSpaceName."

        static let scrollView = prefix + "scrollView"
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @ObservedObject var viewModel = AccountFormViewModel(
        flowType: .create(
            creator: CryptoAccountFormViewCreator(
                userWalletModelSubject: CurrentValueSubject(FakeUserWalletModel.wallet3Cards),
                walletSelection: .selectable
            )
        ),
        coordinator: nil
    )

    Color.clear
        .sheet(isPresented: .constant(true)) {
            NavigationStack {
                AccountFormView(viewModel: viewModel)
            }
        }
}
