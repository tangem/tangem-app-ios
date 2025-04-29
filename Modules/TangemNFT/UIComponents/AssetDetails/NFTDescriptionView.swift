//
//  SwiftUIView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUIUtils
import TangemUI

struct NFTDescriptionView: View {
    let text: String
    let backgroundColor: Color
    let readMoreAction: () -> Void

    @State private var actualHeight: CGFloat = 0
    @State private var intrinsicHeight: CGFloat = 0

    var body: some View {
        styledText
            .lineLimit(Constants.lineLimit)
            .readGeometry(\.frame.height) { actualHeight = $0 }
            .background(
                styledText
                    .fixedSize(horizontal: false, vertical: true)
                    .hidden()
                    .readGeometry(\.frame.height) { intrinsicHeight = $0 }
            )
            .if(isTruncated) {
                $0.overlay(readMoreButton, alignment: .bottomTrailing)
            }
    }

    private var styledText: some View {
        Text(text)
            .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
    }

    private var readMoreButton: some View {
        Button(action: readMoreAction) {
            Text(readMoreOffsettedText)
                .style(Fonts.Regular.footnote, color: Colors.Text.accent)
                .background(
                    LinearGradient(
                        stops: [
                            Gradient.Stop(color: backgroundColor.opacity(0.5), location: 0),
                            Gradient.Stop(color: backgroundColor.opacity(0.7), location: 0.1),
                            Gradient.Stop(color: backgroundColor, location: 0.2),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
        .buttonStyle(.defaultScaled)
    }

    private var readMoreOffsettedText: String {
        let leftOffset = String(repeating: " ", count: 6)
        let rightOffset = String(repeating: " ", count: 4)
        return leftOffset + Localization.commonReadMore + rightOffset
    }

    private var isTruncated: Bool {
        abs(actualHeight - intrinsicHeight) > Constants.heightDifferenceTolerance
    }
}

private extension NFTDescriptionView {
    enum Constants {
        static let lineLimit = 3
        static let heightDifferenceTolerance = 0.5
    }
}

#if DEBUG
#Preview {
    NFTDescriptionView(
        text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec ac dictum ligula. Vestibulum placerat imperdiet feugiat. Fusce vestibulum sagittis convallis. Quisque in ante et ipsum auctor mattis eu in velit. Duis at consequat elit. Nam posuere turpis in dolor finibus, a fringilla tortor dictum. Duis at congue risus, ac rhoncus ligula. Vestibulum tincidunt malesuada maximus. Fusce rutrum porta mi ac lobortis.",
        backgroundColor: Colors.Background.action,
        readMoreAction: {}
    )
}
#endif
