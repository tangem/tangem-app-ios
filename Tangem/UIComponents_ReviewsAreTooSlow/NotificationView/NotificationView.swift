//
//  NotificationView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

// MARK: - View

public struct NotificationView: View {
    // MARK: - Properties

    private(set) var viewModel: NotificationViewModel

    // MARK: - SetupUI

    public var body: some View {
        Button {
            viewModel.primaryTapAction?()
        } label: {
            HStack(alignment: .center, spacing: 0) {
                viewModel.input.mainIcon.image
                    .frame(width: 20, height: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.input.title)
                        .style(Fonts.Bold.footnote, color: Colors.Text.primary1)

                    if let description = viewModel.input.description {
                        Text(description)
                            .style(Fonts.Bold.caption1, color: Colors.Text.tertiary)
                    }
                }
                .padding(.leading, 10)

                Spacer()

                if let moreIcon = viewModel.input.moreIcon {
                    Button {
                        viewModel.secondaryTapAction?()
                    } label: {
                        moreIcon.image
                            .frame(width: 20, height: 20)
                    }
                    .disabled(viewModel.secondaryTapAction == nil)
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Colors.Button.secondary)
            .contentShape(Rectangle())
            .cornerRadiusContinuous(16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

struct NotificationView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationView(
            viewModel: .init(
                input: .init(
                    mainIcon: Assets.attention,
                    title: "NotificationView title",
                    description: "NotificationView description",
                    moreIcon: Assets.search
                ),
                primaryTapAction: nil,
                secondaryTapAction: nil
            )
        )
        .padding(.horizontal, 0)
    }
}
