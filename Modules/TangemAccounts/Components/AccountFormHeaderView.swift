//
//  AccountFormHeaderView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils
import TangemLocalization

public struct AccountFormHeaderView: View {
    @Binding var accountName: String
    @State private var originalTextFieldHeight: CGFloat = 0
    @FocusState.Binding private var isFocused: Bool

    private let maxCharacters: Int
    private let placeholderText: String
    private let accountIconViewData: AccountIconView.ViewData

    public init(
        accountName: Binding<String>,
        maxCharacters: Int,
        placeholderText: String,
        accountIconViewData: AccountIconView.ViewData,
        isFocused: FocusState<Bool>.Binding
    ) {
        _accountName = accountName
        _isFocused = isFocused
        self.maxCharacters = maxCharacters
        self.placeholderText = placeholderText
        self.accountIconViewData = accountIconViewData
    }

    public var body: some View {
        VStack(alignment: .center, spacing: 0) {
            colorWithPreview
                .padding(.bottom, 34)

            Text(Localization.accountFormName)
                .style(Fonts.Bold.caption1, color: Colors.Text.tertiary)

            nameInput
        }
        .roundedBackground(with: Colors.Background.action, verticalPadding: 20, horizontalPadding: 16)
    }

    private var colorWithPreview: some View {
        HStack {
            Spacer()
            AccountIconView(data: accountIconViewData)
                .settings(.largeSized)
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
                accountName = String(newValue.prefix(maxCharacters))
            }
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview {
    @Previewable @State var accountName = ""
    @Previewable @FocusState var isFocused: Bool

    ZStack {
        Color.gray
        VStack {
            AccountFormHeaderView(
                accountName: $accountName,
                maxCharacters: 20,
                placeholderText: "New account",
                accountIconViewData: AccountIconView.ViewData(
                    backgroundColor: Colors.Accounts.vitalGreen,
                    nameMode: .letter("N")
                ),
                isFocused: $isFocused
            )

            AccountFormHeaderView(
                accountName: $accountName,
                maxCharacters: 20,
                placeholderText: "New account",
                accountIconViewData: AccountIconView.ViewData(
                    backgroundColor: Colors.Accounts.ufoGreen,
                    nameMode: .imageType(Assets.Accounts.airplane)
                ),
                isFocused: $isFocused
            )
        }
        .padding(.horizontal, 16)
    }
}
#endif
