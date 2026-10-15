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
        backgroundColor: Color = DesignSystem.Color.bgSecondary,
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
                .padding(.bottom, 28)

            Text(title)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
                .padding(.bottom, 4)

            nameInput

            if let errorMessage {
                Text(errorMessage)
                    .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textAccentRed)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
        }
        .padding(.top, 36)
        .padding(.bottom, style.contentBottomPadding)
        .roundedBackground(with: backgroundColor, verticalPadding: 0, horizontalPadding: 16, radius: 24)
    }

    private var colorWithPreview: some View {
        HStack {
            Spacer()
            AccountIconView(data: accountIconViewData)
                .settings(style.avatarSettings)
                .if(style.isAvatarCircular) { $0.clipShape(Circle()) }
            Spacer()
        }
    }

    private var nameInput: some View {
        TextField(placeholderText, text: $accountName)
            .tint(DesignSystem.Color.textPrimary)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(style.nameMinimumScaleFactor)
            .focused($isFocused)
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            originalTextFieldHeight = proxy.size.height
                        }
                }
            )
            .style(DesignSystem.Font.headingMediumToken, color: DesignSystem.Color.textPrimary)
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
        let contentBottomPadding: CGFloat
        let avatarSettings: AccountIconView.Settings
        let isAvatarCircular: Bool
        let enforcesMaxLength: Bool
        let nameMinimumScaleFactor: CGFloat

        public static let accounts = Style(
            contentBottomPadding: 24,
            avatarSettings: .redesignLargeSized,
            isAvatarCircular: false,
            enforcesMaxLength: true,
            nameMinimumScaleFactor: 0.5
        )

        public static let addressBook = Style(
            contentBottomPadding: 36,
            avatarSettings: .largeSized,
            isAvatarCircular: true,
            enforcesMaxLength: false,
            nameMinimumScaleFactor: 1
        )
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
