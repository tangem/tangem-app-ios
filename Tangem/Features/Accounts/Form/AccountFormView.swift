//
//  AccountFormView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
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
    @State private var buttonMinY: CGFloat = 0

    @State private var shouldShowShadow = false
    @FocusState private var isNameFocused: Bool

    // MARK: Constants

    private let coordinateSpaceName = UUID()

    var body: some View {
        ZStack(alignment: .bottom) {
            content

            overlayButtonView
        }
        .padding(.horizontal, 16)
        .background(Colors.Background.tertiary)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .withCloseButton(placement: .topBarTrailing, style: .icon) {
            viewModel.onClose()
        }
        .ignoresSafeArea(.keyboard)
        .alert(item: $viewModel.alert, content: { $0.alert })
        .submitLabel(.done)
        .onSubmit {
            // Do NOT access SwiftUI internal state (@State, @FocusState, @Binding, @StateObject, etc) inside the `onSubmit(of:_:)` closure.
            // This causes a memory leak as soon as the text field becomes the first responder.
            // See https://stackoverflow.com/questions/70510596 and https://stackoverflow.com/questions/78763987 for more details
            UIResponder.current?.resignFirstResponder()
        }
        .onAppear {
            viewModel.onAppear()
            isNameFocused = true
        }
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
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                        .transition(.opacity)
                }
            }
            .readGeometry(\.size.height) { height in
                contentHeight = height
            }
            .readContentOffset(inCoordinateSpace: .named(coordinateSpaceName)) { point in
                let contentMaxY = contentHeight - point.y
                shouldShowShadow = contentMaxY > containerHeight
            }
        }
        .coordinateSpace(name: coordinateSpaceName)
        .scrollDismissesKeyboard(.immediately)
        .scrollBounceBehavior(.basedOnSize)
        .readGeometry(\.size.height) { height in
            containerHeight = height
        }
        .animation(.default, value: viewModel.description)
    }

    private var overlayButtonView: some View {
        MainButton(
            title: viewModel.buttonTitle,
            isLoading: viewModel.isLoading,
            isDisabled: viewModel.mainButtonDisabled,
            action: viewModel.onMainButtonTap
        )
        .padding(.bottom, 6)
        .background(
            ListFooterOverlayShadowView()
                .hidden(!shouldShowShadow)
        )
        .readGeometry(\.frame, inCoordinateSpace: .named(coordinateSpaceName)) { frame in
            buttonHeight = frame.height
            buttonMinY = frame.minY
        }
    }

    private var mainContent: some View {
        VStack(spacing: 12) {
            AccountFormHeaderView(
                accountName: $viewModel.accountName,
                maxCharacters: viewModel.maxNameLength,
                placeholderText: viewModel.placeholder,
                accountIconViewData: viewModel.iconViewData,
                isFocused: $isNameFocused
            )

            AccountFormGridView(
                selectedItem: $viewModel.selectedColor,
                items: viewModel.colors,
                content: { colorItem, isSelected in
                    makeColorItem(color: colorItem.color, isSelected: isSelected)
                }
            )

            AccountFormGridView(
                selectedItem: $viewModel.selectedIcon,
                items: viewModel.images,
                content: { imageItem, isSelected in
                    makeIconItem(kind: imageItem.kind, isSelected: isSelected)
                }
            )
        }
    }

    private func makeColorItem(color: Color, isSelected: Bool) -> some View {
        Circle()
            .fill(color)
            .overlay(makeItemOverlayView(isSelected: isSelected, strokeColor: color))
    }

    private func makeIconItem(kind: GridItemImageKind, isSelected: Bool) -> some View {
        let imageSelectedColor = switch kind {
        case .image: Colors.Text.secondary
        case .letter: Colors.Text.accent
        }

        let imageNotSelectedColor = switch kind {
        case .image: Colors.Text.tertiary
        case .letter: Colors.Text.accent
        }

        let backgroundColor = switch kind {
        case .image: Colors.Field.focused
        case .letter: Colors.Text.accent.opacity(0.1)
        }

        let strokeColor = switch kind {
        case .image: Colors.Text.secondary
        case .letter: Colors.Icon.accent
        }

        return Circle()
            .fill(backgroundColor)
            .overlay(
                kind.imageType.image
                    .renderingMode(.template)
                    .resizable()
                    .padding(8)
                    .foregroundStyle(isSelected ? imageSelectedColor : imageNotSelectedColor)
            )
            .overlay(makeItemOverlayView(isSelected: isSelected, strokeColor: strokeColor))
    }

    private func makeItemOverlayView(isSelected: Bool, strokeColor: Color) -> some View {
        Circle()
            .strokeBorder(AccountFormGridViewConstants.backgroundColor, lineWidth: isSelected ? 4 : 0)
            .overlay(
                Circle()
                    .strokeBorder(strokeColor, lineWidth: isSelected ? 2 : 0)
            )
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview {
    @Previewable @ObservedObject var viewModel = AccountFormViewModel(
        accountModelsManager: AccountModelsManagerMock(),
        flowType: .create(.crypto),
        closeAction: { _ in }
    )

    Color.clear
        .sheet(isPresented: .constant(true)) {
            NavigationStack {
                AccountFormView(viewModel: viewModel)
            }
        }
}
#endif
