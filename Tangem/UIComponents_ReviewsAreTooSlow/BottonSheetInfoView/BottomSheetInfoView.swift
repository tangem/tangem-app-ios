//
//  BottomSheetInfoView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

public struct BottomSheetInfoView: View {
    // MARK: - Properties

    private(set) var viewModel: BottomSheetInfoViewModel

    // MARK: - SetupUI

    public var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Spacer(minLength: 44)

            viewModel.input.icon.image
                .frame(width: 40, height: 40)

            Spacer(minLength: 28)

            VStack(alignment: .center, spacing: 10) {
                Text(viewModel.input.title)
                    .font(.system(size: 28, weight: .semibold))
                    .padding(.horizontal, 34)

                if let description = viewModel.input.description {
                    Text(description)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color.gray)
                        .foregroundColor(Color.tangemTextGray)
                        .padding(.horizontal, 34)
                }
            }
            .padding(.horizontal, 16)

            Spacer(minLength: 40)

            if let titleButton = viewModel.input.titleButton {
                MainButton(
                    title: titleButton,
                    style: .secondary,
                    action: viewModel.tapButtonAction ?? {}
                )
                .disabled(viewModel.tapButtonAction == nil)
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 16)
            }
        }
    }
}

public struct BottomSheetInfoViewModel: Identifiable {
    public struct Input {
        private(set) var icon: ImageType
        private(set) var title: String
        private(set) var description: String?
        private(set) var titleButton: String?
    }

    public let id: UUID = .init()

    private(set) var input: Input
    private(set) var tapButtonAction: (() -> Void)?
}

// MARK: - Previews

@available(iOS 15.0, *)
struct BottomSheetInfoView_Previews: PreviewProvider {
    struct StatableContainer: View {
        @State private var item: BottomSheetInfoViewModel?

        var body: some View {
            ZStack {
                Color.green
                    .edgesIgnoringSafeArea(.all)

                Button("Bottom sheet isShowing \((item != nil).description)") {
                    toggleItem()
                }
                .font(Fonts.Bold.body)
                .offset(y: -200)

                NavHolder()
                    .bottomSheet(item: $item) {
                        BottomSheetInfoView(viewModel: $0)
                    }
            }
        }

        func toggleItem() {
            let isShowing = item != nil

            if !isShowing {
                item = BottomSheetInfoViewModel(
                    input: .init(
                        icon: Assets.attention,
                        title: "Backup your card",
                        description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
                        titleButton: "test"
                    )
                )
            } else {
                item = nil
            }
        }
    }

    static var previews: some View {
        StatableContainer()
    }
}
