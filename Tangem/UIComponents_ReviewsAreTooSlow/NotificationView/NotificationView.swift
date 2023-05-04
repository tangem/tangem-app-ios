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
            viewModel.tapAroundAction?()
        } label: {
            HStack(alignment: .center, spacing: 0) {
                viewModel.input.mainIcon.image
                    .frame(width: 20, height: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.input.title)
                        .font(.system(size: 15, weight: .medium))

                    if let description = viewModel.input.description {
                        Text(description)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color.gray)
                            .foregroundColor(Color.tangemTextGray)
                    }
                }
                .padding(.leading, 10)

                Spacer()

                if let moreIcon = viewModel.input.moreIcon {
                    Button {
                        viewModel.tapMoreAction?()
                    } label: {
                        moreIcon.image
                            .frame(width: 20, height: 20)
                    }
                    .disabled(viewModel.tapMoreAction == nil)
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Colors.Button.secondary)
            .contentShape(Rectangle())
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ViewModel

public struct NotificationViewModel: Identifiable {
    public struct Input {
        private(set) var mainIcon: ImageType
        private(set) var title: String
        private(set) var description: String?
        private(set) var moreIcon: ImageType?
    }

    public let id = UUID()

    private(set) var input: Input
    private(set) var tapAroundAction: (() -> Void)?
    private(set) var tapMoreAction: (() -> Void)?
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
                )
            )
        )
        .padding(.horizontal, 0)
    }
}
