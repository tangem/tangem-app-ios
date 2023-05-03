//
//  NotificationView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct NotificationView: View {
    // MARK: - Properties

    private(set) var mainIcon: ImageType
    private(set) var title: String
    private(set) var description: String?
    private(set) var moreIcon: ImageType?

    private(set) var tapAroundAction: (() -> Void)?
    private(set) var tapMoreAction: (() -> Void)?

    // MARK: - SetupUI

    var body: some View {
        Button {
            tapAroundAction?()
        } label: {
            HStack(alignment: .center, spacing: 0) {
                mainIcon.image
                    .frame(width: 20, height: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))

                    if let description = description {
                        Text(description)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color.gray)
                            .foregroundColor(Color.tangemTextGray)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 10)

                Spacer()

                if let moreIcon = moreIcon {
                    Button {
                        tapMoreAction?()
                    } label: {
                        moreIcon.image
                            .frame(width: 20, height: 20)
                    }
                    .disabled(tapMoreAction == nil)
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

// MARK: - Previews

struct NotificationView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationView(
            mainIcon: Assets.attention,
            title: "NotificationView title",
            description: "NotificationView description",
            moreIcon: Assets.search,
            tapAroundAction: {
                print("tapAroundAction")
            },
            tapMoreAction: {
                print("tapMoreAction")
            }
        )
        .padding(.horizontal, 0)
    }
}
