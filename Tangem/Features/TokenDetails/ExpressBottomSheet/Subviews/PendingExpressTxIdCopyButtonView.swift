//
//  PendingExpressTxIdCopyButtonView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUIUtils

struct PendingExpressTxIdCopyButtonViewModel {
    let transactionID: String

    func copyTransactionID() {
        UIPasteboard.general.string = transactionID

        let toastView = SuccessToast(text: Localization.expressTransactionIdCopied)
        Toast(view: toastView).present(layout: .top(padding: 14), type: .temporary())
    }
}

struct PendingExpressTxIdCopyButtonView: View {
    let viewModel: PendingExpressTxIdCopyButtonViewModel

    var body: some View {
        Button(action: viewModel.copyTransactionID) {
            HStack(spacing: 4) {
                Assets.Glyphs.copy.image
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 16, height: 16)
                    .foregroundColor(Colors.Icon.informative)

                Text(Localization.expressTransactionId(viewModel.transactionID))
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            }
        }
        .lineLimit(1)
    }
}
