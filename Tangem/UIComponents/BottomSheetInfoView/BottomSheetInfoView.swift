//
//  BottomSheetInfoView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct BottomSheetInfoView: View {
    // MARK: - Properties

    let viewModel: BottomSheetInfoViewModel

    // MARK: - SetupUI

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 44)

            viewModel.icon.image
                .frame(width: 40, height: 40)

            Spacer(minLength: 28)

            VStack(spacing: 10) {
                Text(viewModel.title)
                    .style(Fonts.Bold.title1, color: Colors.Text.primary1)
                    .multilineTextAlignment(.center)

                if let description = viewModel.description {
                    Text(description)
                        .style(Fonts.Bold.subheadline, color: Colors.Text.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 16)

            Spacer(minLength: 40)

            if let buttonTitle = viewModel.buttonTitle {
                MainButton(
                    title: buttonTitle,
                    style: .secondary,
                    action: viewModel.buttonTapAction ?? {}
                )
                .disabled(viewModel.buttonTapAction == nil)
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Previews

@available(iOS 17.0, *)
#Preview {
    @Previewable @State var item: BottomSheetInfoViewModel?

    func makeBottomSheetInfoPreviewViewModel() -> BottomSheetInfoViewModel {
        BottomSheetInfoViewModel(
            input: .init(
                icon: Assets.attention,
                title: "Backup your card",
                description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
                buttonTitle: "test"
            ),
            buttonTapAction: nil
        )
    }

    return ZStack {
        Button("Bottom sheet isShowing \((item != nil).description)") {
            item = item == nil ? makeBottomSheetInfoPreviewViewModel() : nil
        }
        .font(Fonts.Bold.body)
        .offset(y: -200)

        NavHolder()
            .bottomSheet(item: $item, backgroundColor: Colors.Background.tertiary) {
                BottomSheetInfoView(viewModel: $0)
            }
    }
}
