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

struct AccountFormHeaderView: View {
    @Binding var accountName: String
    @State private var originalTextFieldHeight: CGFloat = 0

    let placeholderText: String
    let color: Color
    let previewType: AccountFormHeaderType

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            colorWithPreview
                .padding(.bottom, 34)

            // [REDACTED_TODO_COMMENT]
            Text("Account name")
                .style(Fonts.Bold.caption1, color: Colors.Text.tertiary)

            nameInput
        }
        .roundedBackground(with: Colors.Background.action, verticalPadding: 20, horizontalPadding: 16)
    }

    private var colorWithPreview: some View {
        HStack {
            Spacer()
            preview
                .frame(width: 40, height: 40)
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(color)
                        .animation(.default, value: color)
                )
                .animation(.default, value: previewType)

            Spacer()
        }
    }

    @ViewBuilder
    private var preview: some View {
        switch previewType {
        case .letter(let letter):
            Text(letter)
                .style(Fonts.Bold.largeTitle, color: Colors.Text.constantWhite)

        case .image(let image, let config):
            image
                .renderingMode(.template)
                .resizable()
                .foregroundStyle(Colors.Text.constantWhite)
                .opacity(config.opacity)
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

enum AccountFormHeaderType: Equatable {
    case letter(String)
    case image(Image, config: ImageConfig = .default)
}

extension AccountFormHeaderType {
    struct ImageConfig: Equatable {
        var opacity: Double = 1

        static let `default`: Self = ImageConfig()
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
                color: Colors.Accounts.darkGreen,
                previewType: .letter("N")
            )

            AccountFormHeaderView(
                accountName: $accountName,
                placeholderText: "New account",
                color: Colors.Accounts.darkGreen,
                previewType: .image(Assets.Accounts.airplane.image)
            )
        }
        .padding(.horizontal, 16)
    }
}
#endif
