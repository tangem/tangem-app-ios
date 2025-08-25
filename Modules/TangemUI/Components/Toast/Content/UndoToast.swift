//
//  UndoToastView.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUIUtils

public protocol UndoToastSettings {
    var image: ImageType { get }
    var title: String { get }
}

public struct UndoToast: View {
    private let settings: UndoToastSettings
    private let undoAction: () -> Void

    public init(settings: any UndoToastSettings, undoAction: @escaping () -> Void) {
        self.settings = settings
        self.undoAction = undoAction
    }

    public var body: some View {
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

// MARK: - Previews

#if DEBUG
private struct PreviewUndoToastSettings: UndoToastSettings {
    let image: ImageType
    let title: String
}

#Preview("Light Mode") {
    VStack {
        UndoToast(settings: PreviewUndoToastSettings(image: Assets.crossedEyeIcon, title: Localization.toastBalancesHidden)) {}

        UndoToast(settings: PreviewUndoToastSettings(image: Assets.eyeIconMini, title: Localization.toastBalancesShown)) {}
    }
    .environment(\.colorScheme, .light)
}

#Preview("Dark Mode") {
    VStack {
        UndoToast(settings: PreviewUndoToastSettings(image: Assets.crossedEyeIcon, title: Localization.toastBalancesHidden)) {}

        UndoToast(settings: PreviewUndoToastSettings(image: Assets.eyeIconMini, title: Localization.toastBalancesShown)) {}
    }
    .environment(\.colorScheme, .dark)
}
#endif // DEBUG
