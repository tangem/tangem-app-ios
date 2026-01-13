//
//  WordsCaptureProtectionView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct WordsCaptureProtectionView: View {
    let words: [String]
    let indexRange: Range<Int>
    let verticalSpacing: CGFloat

    @State private var wordsColumnMaxWidth: CGFloat?

    var body: some View {
        // Do not remove Lazy Stack here; it updates its child views when they enter into the visible viewport,
        // which in turn fixes an incorrect layout of `wordView` when `wordView` is initially placed outside
        // the visible viewport. See [REDACTED_INFO] for details
        LazyVStack(alignment: .leading, spacing: verticalSpacing) {
            ForEach(indexRange, id: \.self) { index in
                HStack(alignment: .center, spacing: 0) {
                    Text("\(index + 1). ") // The space character after the dot is 'U+2009 THIN SPACE'
                        .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
                        .fixedSize()
                        .readGeometry(\.size.width, onChange: updateWordsColumnMaxWidth(width:))
                        .frame(width: wordsColumnMaxWidth, alignment: .leading)

                    let wordView = Text("\(words[index])")
                        .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                    wordView
                        .fixedSize()

                    Spacer()
                }
            }
        }
    }

    private func updateWordsColumnMaxWidth(width: CGFloat) {
        wordsColumnMaxWidth = max(wordsColumnMaxWidth ?? .zero, width)
    }
}
