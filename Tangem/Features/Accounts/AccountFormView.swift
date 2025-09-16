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

struct AccountFormView: View {
    @ObservedObject var viewModel: AccountFormViewModel

    @State private var contentHeight: CGFloat = 0
    @State private var containerHeight: CGFloat = 0

    @State private var buttonHeight: CGFloat = 0
    @State private var buttonMinY: CGFloat = 0

    @State private var shouldShowShadow = false

    private let coordinateSpaceName = UUID()

    var body: some View {
        ZStack(alignment: .bottom) {
            scrollableContent

            overlayButtonView
        }
        .padding(.horizontal, 16)
        .background(Colors.Background.tertiary)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .withCloseButton(placement: .topBarTrailing, style: .crossImage) {
            viewModel.onClose()
        }
        .ignoresSafeArea(.keyboard)
        .alert(item: $viewModel.alert, content: { $0.alert })
    }

    private var scrollableContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 8) {
                mainContent

                Text(viewModel.bottomText)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
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
        .scrollDisabledBackport(contentHeight <= containerHeight)
        .readGeometry(\.size.height) { height in
            containerHeight = height
        }
    }

    private var overlayButtonView: some View {
        MainButton(
            title: viewModel.buttonTitle,
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
                color: viewModel.selectedColor.color,
                nameMode: viewModel.nameMode
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
        userWalletId: .init(value: Data()),
        accountIndex: 1,
        accountModelsManager: AccountModelsManagerMock(),
        flowType: .create,
        closeAction: {}
    )

    Color.clear
        .sheet(isPresented: .constant(true)) {
            NavigationView {
                AccountFormView(viewModel: viewModel)
            }
        }
}
#endif
