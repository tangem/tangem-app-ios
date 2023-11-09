//
//  SendWalletSummaryView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendWalletSummaryView: View {
    let viewModel: SendWalletSummaryViewModel

    var body: some View {
        GroupedSection(viewModel) { viewModel in
            VStack(alignment: .leading, spacing: 8) {
                Text(TangemRichTextFormatter().format(Localization.sendFromWallet(viewModel.walletName), fontSize: UIFonts.Regular.caption1.pointSize))
                    .style(Fonts.Regular.caption1, color: Colors.Text.secondary)

                Text(viewModel.totalBalance)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            }
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .backgroundColor(Colors.Button.disabled)
    }
}

// MARK: - Rich text formatter

private struct TangemRichTextFormatter {
    // Formatting rich text as NSAttributedString
    // Supported formats: **bold**
    func format(_ string: String, fontSize: CGFloat) -> NSAttributedString {
        var originalString = string

        let regex = try! NSRegularExpression(pattern: "\\*{2}.+?\\*{2}")

        let wholeRange = NSRange(location: 0, length: (originalString as NSString).length)
        let matches = regex.matches(in: originalString, range: wholeRange)

        let attributedString = NSMutableAttributedString(string: originalString)

        if let match = matches.first {
            let formatterTagLength = 2

            let boldTextFormatted = String(originalString[Range(match.range, in: originalString)!])
            let boldText = boldTextFormatted.dropFirst(formatterTagLength).dropLast(formatterTagLength)

            originalString = originalString.replacingOccurrences(of: boldTextFormatted, with: boldText)
            attributedString.setAttributedString(NSAttributedString(string: originalString))

            // UIKit's .semibold corresponds SwiftUI bold font
            let boldFont = UIFont.systemFont(ofSize: fontSize, weight: .semibold)
            let boldTextRange = NSRange(location: match.range.location, length: match.range.length - 2 * formatterTagLength)
            attributedString.addAttribute(.font, value: boldFont, range: boldTextRange)
        }

        return attributedString
    }
}

#Preview {
    GroupedScrollView {
        SendWalletSummaryView(viewModel: SendWalletSummaryViewModel(walletName: "Family Wallet", totalBalance: "2 130,88 USDT (2 129,92 $)"))
    }
    .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
}
