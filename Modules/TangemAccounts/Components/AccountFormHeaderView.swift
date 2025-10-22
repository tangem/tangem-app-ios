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

    private let placeholderText: String
    private let color: Color
    private let nameMode: AccountIconView.NameMode

    public init(
        accountName: Binding<String>,
        placeholderText: String,
        color: Color,
        nameMode: AccountIconView.NameMode
    ) {
        _accountName = accountName
        self.placeholderText = placeholderText
        self.color = color
        self.nameMode = nameMode
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
            AccountIconView(backgroundColor: color, nameMode: nameMode)
                .cornerRadius(24)
                .padding(24)
                .frame(width: 40, height: 40)
            Spacer()
        }
    }

    private var nameInput: some View {
        TextField(placeholderText, text: $accountName)
            .tint(Colors.Text.primary1)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.5)
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
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview {
    @Previewable @State var accountName = ""

    ZStack {
        Color.gray
        VStack {
            AccountFormHeaderView(
                accountName: $accountName,
                placeholderText: "New account",
                color: Colors.Accounts.vitalGreen,
                nameMode: .letter("N")
            )

            AccountFormHeaderView(
                accountName: $accountName,
                placeholderText: "New account",
                color: Colors.Accounts.ufoGreen,
                nameMode: .imageType(Assets.Accounts.airplane)
            )
        }
        .padding(.horizontal, 16)
    }
}
#endif
