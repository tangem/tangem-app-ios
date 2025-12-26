//
//  CustomSearchBar.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation
import TangemLocalization
import TangemAssets
import TangemUIUtils

public struct CustomSearchBar: View {
    @Binding var searchText: String
    private let placeholder: String
    private let keyboardType: UIKeyboardType
    private let style: Style

    @State private var isEditing: Bool = false
    private var onEditingChanged: ((_ isEditing: Bool) -> Void)?
    private var clearButtonAction: (() -> Void)?
    private var cancelButtonAction: (() -> Void)?

    @FocusState private var isFocused: Bool

    private var innerPadding: CGFloat = 12

    public init(
        searchText: Binding<String>,
        placeholder: String,
        keyboardType: UIKeyboardType = .default,
        style: Style = .default,
        clearButtonAction: (() -> Void)? = nil,
        cancelButtonAction: (() -> Void)? = nil,
    ) {
        _searchText = searchText
        self.placeholder = placeholder
        self.keyboardType = keyboardType
        self.style = style
        self.clearButtonAction = clearButtonAction
        self.cancelButtonAction = cancelButtonAction
    }

    public var body: some View {
        HStack(spacing: 10) {
            searchBar

            if isEditing {
                cancelButton
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: isEditing)
    }

    private var searchBar: some View {
        HStack(spacing: 4) {
            Assets.search.image
                .renderingMode(.template)
                .foregroundColor(Colors.Icon.informative)
                .frame(width: 16, height: 16)
                .padding(.all, 4)

            HStack(spacing: 4) {
                TextField(placeholder, text: $searchText, prompt: placeholderView)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
                    .keyboardType(keyboardType)
                    .autocorrectionDisabled()
                    .focused($isFocused)
                    .onChange(of: isFocused, perform: { newValue in
                        isEditing = newValue
                        onEditingChanged?(newValue)
                    })

                clearButton
            }
        }
        .padding(.all, innerPadding)
        .background(background)
        .onTapGesture {
            isFocused = true
        }
    }

    private var placeholderView: Text {
        Text(placeholder)
            .font(Fonts.Regular.subheadline)
            .foregroundColor(Colors.Text.tertiary)
    }

    private var clearButton: some View {
        Button {
            if let clearButtonAction {
                clearButtonAction()
            } else {
                searchText = ""
            }
        } label: {
            Assets.clear.image
                .renderingMode(.template)
                .frame(width: 16, height: 16)
                .foregroundColor(Colors.Icon.informative)
                .padding(.all, 4)
        }
        .hidden(searchText.isEmpty)
    }

    private var cancelButton: some View {
        Button {
            if let cancelButtonAction {
                cancelButtonAction()
            } else {
                searchText = ""
            }
            UIApplication.shared.endEditing()
        } label: {
            Text(Localization.commonCancel)
                .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
        }
    }

    @ViewBuilder
    private var background: some View {
        let background = RoundedRectangle(cornerRadius: 14)

        switch style {
        case .default:
            background
                .fill(Colors.Field.primary)
        case .translucent:
            background
                .fill(.bar)
        case .focused:
            background
                .fill(Colors.Field.focused)
        }
    }
}

// MARK: - Setupable protocol conformance

extension CustomSearchBar: Setupable {
    public func onEditingChanged(_ closure: ((_ isEditing: Bool) -> Void)?) -> Self {
        map { $0.onEditingChanged = closure }
    }

    public func innerPadding(_ padding: CGFloat) -> Self {
        map { $0.innerPadding = padding }
    }
}

// MARK: - Auxiliary types

public extension CustomSearchBar {
    enum InputResult {
        case text(String)
        case clear
    }

    enum Style {
        case `default`
        case translucent
        case focused
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 17.0, *)
#Preview("Light appearance") {
    @Previewable @State var text = ""
    StatefulPreviewWrapper(text) { text in
        CustomSearchBar(
            searchText: text,
            placeholder: Localization.commonSearch,
            clearButtonAction: {},
            cancelButtonAction: {},
        )
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, max(UIApplication.safeAreaInsets.bottom, 20))
        .background(Colors.Background.primary)
    }
}

@available(iOS 17.0, *)
#Preview("Dark appearance", traits: .sizeThatFitsLayout) {
    @Previewable @State var text = ""
    StatefulPreviewWrapper(text) { text in
        CustomSearchBar(
            searchText: text,
            placeholder: Localization.commonSearch,
            clearButtonAction: {},
            cancelButtonAction: {}
        )
        .padding(.horizontal, 16)
    }
    .preferredColorScheme(.dark)
}
#endif // DEBUG
