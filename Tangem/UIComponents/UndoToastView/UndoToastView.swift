//
//  UndoToastView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets

struct UndoToastView: View {
    let settings: UndoToastSettings
    let undoAction: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            titleView
                .padding(.horizontal, 8)

            Separator(
                height: .minimal,
                color: Colors.Stroke.secondary,
                axis: .vertical
            )
            .frame(height: 12)

            Button(action: undoAction) {
                Text(Localization.toastUndo)
                    .style(Fonts.Regular.footnote, color: Colors.Text.primary2)
                    .padding(.vertical, 9) // 8pt plus extra 1pt to match footnote font line height from figma, [REDACTED_TODO_COMMENT]
                    .padding(.horizontal, 8)
            }
        }
        .padding(.horizontal, 6)
        .background(Colors.Icon.secondary)
        .cornerRadiusContinuous(10)
    }

    private var titleView: some View {
        HStack(spacing: 6) {
            settings.image.image
                .resizable()
                .renderingMode(.template)
                .frame(width: 18, height: 18)
                .foregroundColor(Colors.Icon.inactive)

            Text(settings.title)
                .style(Fonts.Regular.footnote, color: Colors.Text.disabled)
                .lineLimit(1)
        }
    }
}

protocol UndoToastSettings {
    var image: ImageType { get }
    var title: String { get }
}

struct UndoToastView_Preview: PreviewProvider {
    static var previews: some View {
        VStack {
            UndoToastView(settings: BalanceHiddenToastType.hidden) {}

            UndoToastView(settings: BalanceHiddenToastType.shown) {}
        }
        .preferredColorScheme(.light)

        VStack {
            UndoToastView(settings: BalanceHiddenToastType.hidden) {}

            UndoToastView(settings: BalanceHiddenToastType.shown) {}
        }
        .preferredColorScheme(.dark)
    }
}
