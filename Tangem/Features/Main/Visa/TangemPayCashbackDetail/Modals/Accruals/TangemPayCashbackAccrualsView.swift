//
//  TangemPayCashbackAccrualsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemAssets
import TangemLocalization

struct TangemPayCashbackAccrualsView: View {
    let data: TangemPayCashbackAccrualsViewData
    let onDocTap: (URL) -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 16)

            explainerRows

            docRows
        }
        .padding(.bottom, 16)
        .background(DesignSystem.Color.bgSecondary.ignoresSafeArea(edges: .bottom))
    }
}

// MARK: - Subviews

private extension TangemPayCashbackAccrualsView {
    var header: some View {
        BottomSheetHeaderView(title: Localization.tangempayCashbackAccrualsTitle, trailing: {
            TangemUI.Button(
                icon: DesignSystem.Icons.Cross.regular20,
                accessibilityLabel: Localization.commonClose,
                action: onClose
            )
            .size(.x11)
            .styleType(.material(.glass))
        })
        .titleFont(DesignSystem.Font.bodyMediumToken.font)
        .titleColor(DesignSystem.Color.textPrimary)
    }

    var explainerRows: some View {
        VStack(spacing: 0) {
            ForEach(Explainer.allCases) { explainer in
                TangemUI.Row(title: explainer.title, subtitle: explainer.subtitle)
                    .subtitleLineLimit(nil)
                    .verticalAlignment(.top)
                    .showDivider(explainer != Explainer.allCases.last)
                    .start { infoIcon }
            }
        }
    }

    @ViewBuilder
    var docRows: some View {
        if !data.docs.isEmpty {
            VStack(spacing: 0) {
                ForEach(data.docs) { doc in
                    TangemUI.Row(title: doc.title)
                        .titleLineLimit(nil)
                        .verticalAlignment(.top)
                        .showDivider(doc.id != data.docs.last?.id)
                        .onTap { onDocTap(doc.url) }
                        .start { icon(DesignSystem.Icons.Document.regular20) }
                        .end { icon(DesignSystem.Icons.ChevronRight.regular20) }
                }
            }
        }
    }

    var infoIcon: some View {
        icon(DesignSystem.Icons.Info.regular20)
    }

    func icon(_ image: ImageType) -> some View {
        image.image
            .renderingMode(.template)
            .foregroundStyle(DesignSystem.Color.iconSecondary)
    }
}

// MARK: - Explainer

private extension TangemPayCashbackAccrualsView {
    enum Explainer: String, CaseIterable, Identifiable {
        case calculation
        case payment
        case exceptions

        var id: String { rawValue }

        var title: String {
            switch self {
            case .calculation: Localization.tangempayCashbackAccrualsCalcTitle
            case .payment: Localization.tangempayCashbackAccrualsPayTitle
            case .exceptions: Localization.tangempayCashbackAccrualsExceptionsTitle
            }
        }

        var subtitle: String {
            switch self {
            case .calculation: Localization.tangempayCashbackAccrualsCalcDescription
            case .payment: Localization.tangempayCashbackAccrualsPayDescription
            case .exceptions: Localization.tangempayCashbackAccrualsExceptionsDescription
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("With documents") {
    TangemPayCashbackAccrualsView(data: .preview, onDocTap: { _ in }, onClose: {})
        .background(DesignSystem.Color.bgSecondary)
}

#Preview("Without documents") {
    TangemPayCashbackAccrualsView(data: .previewWithoutDocs, onDocTap: { _ in }, onClose: {})
        .background(DesignSystem.Color.bgSecondary)
}
#endif
