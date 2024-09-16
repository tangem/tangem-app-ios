//
//  BasicTooltipView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct BasicTooltipView: View {
    // MARK: - Properties

    @Binding private(set) var isShowBindingValue: Bool
    private(set) var onHideAction: (() -> Void)?
    private(set) var title: String
    private(set) var message: String

    // MARK: - UI

    var body: some View {
        ZStack {
            if isShowBindingValue {
                backgroundView

                tooltipView
            }
        }
    }

    // MARK: - Private Implementation

    private var backgroundView: some View {
        Color.black
            .ignoresSafeArea(.all)
            .opacity(0.3)
            .onTapGesture {
                onHideAction?()
            }
    }

    private var tooltipView: some View {
        VStack(spacing: .zero) {
            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .lineLimit(1)
                    .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                Text(message)
                    .lineLimit(2)
                    .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
            }
            .defaultRoundedBackground()

            Triangle()
                .foregroundStyle(Colors.Background.action)
                .frame(size: .init(width: 20, height: 8))
                .rotationEffect(.degrees(180))
        }
        .padding(.horizontal, 64)
        .padding(.bottom, 96)
    }
}
