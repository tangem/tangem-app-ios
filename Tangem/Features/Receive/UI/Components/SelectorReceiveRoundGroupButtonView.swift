//
//  SelectorReceiveRoundGroupButtonView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct SelectorReceiveRoundGroupButtonView: View {
    let copyAction: () -> Void
    let shareAction: () -> Void

    var body: some View {
        VStack(alignment: .center, spacing: .zero) {
            HStack(spacing: Layout.contentHorizontalSpacing) {
                Button {
                    copyAction()
                } label: {
                    SelectorReceiveRoundButtonView(actionType: .copy)
                }

                Button {
                    shareAction()
                } label: {
                    SelectorReceiveRoundButtonView(actionType: .share)
                }
            }
        }
    }
}

extension SelectorReceiveRoundGroupButtonView {
    private enum Layout {
        /// 12
        static let contentHorizontalSpacing: CGFloat = 12
    }
}

#Preview {
    SelectorReceiveRoundGroupButtonView(copyAction: {}, shareAction: {})
}
