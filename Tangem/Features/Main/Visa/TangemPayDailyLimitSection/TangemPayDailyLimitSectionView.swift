//
//  TangemPayDailyLimitSectionView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

enum TangemPayDailyLimitState: Equatable {
    case loading
    case loaded(currentLimit: String)
    case error
}

struct TangemPayDailyLimitSectionView: View {
    let state: TangemPayDailyLimitState
    let isFrozen: Bool
    let changeAction: () -> Void

    var body: some View {
        switch state {
        case .loading:
            loadingRow
        case .loaded(let currentLimit):
            loadedRow(currentLimit: currentLimit)
        case .error:
            VStack(alignment: .leading, spacing: 14) {
                errorRow
                errorBanner
            }
        }
    }

    private var loadingRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            DefaultHeaderView(Localization.tangempayCardPageDailyLimitTitle)
            HStack(spacing: 12) {
                iconView

                VStack(alignment: .leading, spacing: 0) {
                    Text(Localization.tangempayCardPageDailyLimitCurrentLimit)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

                    Text("—")
                        .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                }

                Spacer()

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Colors.Background.primary)
        .cornerRadiusContinuous(14)
    }

    private func loadedRow(currentLimit: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            DefaultHeaderView(Localization.tangempayCardPageDailyLimitTitle)
                .padding(.bottom, 8)
            HStack(spacing: 12) {
                iconView

                VStack(alignment: .leading, spacing: 0) {
                    Text(Localization.tangempayCardPageDailyLimitCurrentLimit)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

                    Text(currentLimit)
                        .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                        .lineLimit(1)
                }

                Spacer()

                if !isFrozen {
                    Button(action: changeAction) {
                        Text(Localization.tangempayCardPageDailyLimitChange)
                            .style(Fonts.Bold.footnote, color: Colors.Text.primary1)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Colors.Button.secondary)
                            .cornerRadiusContinuous(14)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Colors.Background.primary)
        .cornerRadiusContinuous(14)
    }

    private var errorRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            DefaultHeaderView(Localization.tangempayCardPageDailyLimitTitle)
            HStack(spacing: 12) {
                iconView

                VStack(alignment: .leading, spacing: 0) {
                    Text(Localization.tangempayCardPageDailyLimitCurrentLimit)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

                    Text("—")
                        .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                }

                Spacer()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Colors.Background.primary)
        .cornerRadiusContinuous(14)
    }

    private var errorBanner: some View {
        HStack(spacing: 12) {
            Assets.attention20.image

            VStack(alignment: .leading, spacing: 2) {
                Text(Localization.tangempayCardPageDailyLimitErrorTitle)
                    .style(Fonts.Bold.footnote, color: Colors.Text.primary1)

                Text(Localization.tangempayCardPageDailyLimitErrorDescription)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Colors.Button.disabled)
        .cornerRadiusContinuous(14)
    }

    private var iconView: some View {
        Assets.Visa.dailyLimit.image
    }
}

#Preview {
    VStack(spacing: 8) {
        TangemPayDailyLimitSectionView(state: .loading, isFrozen: false, changeAction: {})
        TangemPayDailyLimitSectionView(state: .loaded(currentLimit: "50"), isFrozen: false, changeAction: {})
        TangemPayDailyLimitSectionView(state: .error, isFrozen: false, changeAction: {})
    }
    .preferredColorScheme(.dark)
}
