//
//  FormHeaderView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemUIUtils
import TangemLocalization

public struct FormHeaderView: View {
    @Binding var accountName: String
    @State private var originalTextFieldHeight: CGFloat = 0
    @FocusState.Binding private var isFocused: Bool

    private let title: String
    private let maxCharacters: Int
    private let placeholderText: String
    private let backgroundColor: Color
    private let accountIconViewData: AccountIconView.ViewData
    private let errorMessage: String?

    private var style: Style = .accounts

    public init(
        accountName: Binding<String>,
        title: String,
        maxCharacters: Int,
        placeholderText: String,
        backgroundColor: Color = Colors.Background.action,
        accountIconViewData: AccountIconView.ViewData,
        errorMessage: String? = nil,
        isFocused: FocusState<Bool>.Binding
    ) {
        _accountName = accountName
        _isFocused = isFocused
        self.title = title
        self.maxCharacters = maxCharacters
        self.placeholderText = placeholderText
        self.backgroundColor = backgroundColor
        self.accountIconViewData = accountIconViewData
        self.errorMessage = errorMessage
    }

    public var body: some View {
        VStack(alignment: .center, spacing: 0) {
            colorWithPreview
                .padding(.bottom, style.avatarBottomPadding)

            Text(title)
                .style(Fonts.Bold.caption1, color: style.titleColor)
                .padding(.bottom, style.titleBottomPadding)

            nameInput

            if let errorMessage {
                Text(errorMessage)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textAccentRed)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
        }
        .roundedBackground(with: backgroundColor, verticalPadding: style.contentVerticalPadding, horizontalPadding: 16, radius: style.cornerRadius)
    }

    private var colorWithPreview: some View {
        HStack {
            Spacer()
            AccountIconView(data: accountIconViewData)
                .settings(.largeSized)
                .if(style.isAvatarCircular) { $0.clipShape(Circle()) }
            Spacer()
        }
    }

    private var nameInput: some View {
        TextField(placeholderText, text: $accountName)
            .tint(Colors.Text.primary1)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.5)
            .focused($isFocused)
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            originalTextFieldHeight = proxy.size.height
                        }
                }
            )
            .style(Fonts.Bold.title1, color: Colors.Text.primary1)
            .frame(height: originalTextFieldHeight)
            // Mikhail Andreev - Needed to be constrained from here coz for some reason it
            // is not possible to do it from ViewModel
            .onChange(of: accountName) { newValue in
                if style.enforcesMaxLength {
                    accountName = String(newValue.prefix(maxCharacters))
                }
            }
            .accessibilityIdentifier(AccountsAccessibilityIdentifiers.accountFormNameInput)
    }
}

// MARK: - Style

public extension FormHeaderView {
    struct Style {
        let cornerRadius: CGFloat
        let contentVerticalPadding: CGFloat
        let avatarBottomPadding: CGFloat
        let titleColor: Color
        let titleBottomPadding: CGFloat
        let isAvatarCircular: Bool
        let enforcesMaxLength: Bool

        public static let accounts = Style(cornerRadius: 14, contentVerticalPadding: 20, avatarBottomPadding: 34, titleColor: Colors.Text.tertiary, titleBottomPadding: 0, isAvatarCircular: false, enforcesMaxLength: true)
        public static let addressBook = Style(cornerRadius: 24, contentVerticalPadding: 36, avatarBottomPadding: 28, titleColor: Colors.Text.secondary, titleBottomPadding: 4, isAvatarCircular: true, enforcesMaxLength: false)
    }
}

// MARK: - Setupable

extension FormHeaderView: Setupable {
    public func style(_ style: Style) -> Self {
        map { $0.style = style }
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @State var accountName = ""
    @Previewable @FocusState var isFocused: Bool

    ZStack {
        Color.gray
        VStack {
            FormHeaderView(
                accountName: $accountName,
                title: Localization.accountFormName,
                maxCharacters: 20,
                placeholderText: "New account",
                accountIconViewData: .composite(
                    backgroundColor: Colors.Accounts.vitalGreen,
                    nameMode: .letter("N")
                ),
                isFocused: $isFocused
            )

            FormHeaderView(
                accountName: $accountName,
                title: Localization.accountFormName,
                maxCharacters: 20,
                placeholderText: "New account",
                accountIconViewData: .composite(
                    backgroundColor: Colors.Accounts.ufoGreen,
                    nameMode: .imageType(Assets.Accounts.airplane)
                ),
                isFocused: $isFocused
            )
        }
        .padding(.horizontal, 16)
    }
}
