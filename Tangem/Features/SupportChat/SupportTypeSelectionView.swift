//
//  SupportTypeSelectionView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI
import TangemAssets

struct SupportTypeSelectionView: View {
    let model: SupportTypeSelectionModel

    var body: some View {
        VStack(spacing: 0) {
            Text(Localization.commonContactSupport)
                .style(Fonts.Bold.title2, color: Colors.Text.primary1)
                .multilineTextAlignment(.center)
                .padding(.top, 24)
                .padding(.horizontal, 16)
                .padding(.bottom, 20)

            Divider()

            Button(action: model.emailAction) {
                Text(Localization.supportSelectorViewEmailButton)
                    .style(Fonts.Regular.body, color: Colors.Text.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }

            Divider()

            Button(action: model.chatAction) {
                Text(Localization.supportSelectorViewChatButton)
                    .style(Fonts.Regular.body, color: Colors.Text.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
        }
        .presentationDetents([.height(Constants.preferredHeight)])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Constants

private extension SupportTypeSelectionView {
    enum Constants {
        static let preferredHeight: CGFloat = 200
    }
}

// MARK: - Previews

#Preview {
    SupportTypeSelectionView(model: SupportTypeSelectionModel(emailAction: {}, chatAction: {}))
}
