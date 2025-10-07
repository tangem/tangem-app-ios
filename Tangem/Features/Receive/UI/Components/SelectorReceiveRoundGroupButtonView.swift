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
            HStack(spacing: 12) {
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

#Preview {
    SelectorReceiveRoundGroupButtonView(copyAction: {}, shareAction: {})
}
