//
//  ScanCardWarningView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct ScanCardWarningView: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 0) {
                HStack(spacing: 12) {
                    icon

                    VStack(alignment: .leading, spacing: 4) {
                        Text("main_scan_card_warning_view_title".localized)
                            .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

                        Text("main_scan_card_warning_view_subtitle")
                            .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Assets.chevron
            }
            .frame(maxWidth: .infinity)
            .padding([.vertical, .horizontal], 16)
            .background(Colors.Background.primary)
            .cornerRadius(14)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var icon: some View {
        ZStack(alignment: .topTrailing) {
            Assets.tangemCircleGrayIcon

            Circle()
                .fill(Colors.Text.attention)
                .padding(3)
                .background(Colors.Background.primary)
                .frame(width: 12, height: 12)
                .cornerRadius(6)
        }
    }
}

struct ScanCardWarningView_Preview: PreviewProvider {
    static var previews: some View {
        ZStack {
            Colors.Background.secondary

            ScanCardWarningView {}.padding()
        }
    }
}
