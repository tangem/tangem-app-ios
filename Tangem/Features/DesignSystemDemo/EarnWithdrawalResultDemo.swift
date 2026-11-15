//
//  EarnWithdrawalResultDemo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct EarnWithdrawalResultDemoView: View {
    @State private var isInProgress = false
    @State private var isLendingOnAave = false
    @State private var hasTransactionLink = true
    @State private var isRightToLeft = false
    @State private var exploreTapCount = 0
    @State private var shareTapCount = 0
    @State private var isPresented = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                controls

                TangemUI.Button(label: "Show result", accessibilityLabel: "Show result") { isPresented = true }
                    .styleType(.primary)
                    .horizontalLayout(.infinity)
            }
            .padding(16)
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .navigationTitle("Earn withdrawal result")
        .fullScreenCover(isPresented: $isPresented) {
            EarnWithdrawalResultContentView(state: state, action: handle)
                .environment(\.layoutDirection, isRightToLeft ? .rightToLeft : .leftToRight)
        }
    }
}

// MARK: - Subviews

private extension EarnWithdrawalResultDemoView {
    var controls: some View {
        VStack(spacing: 8) {
            Toggle("In progress", isOn: $isInProgress)
            Toggle("Lending on Aave", isOn: $isLendingOnAave)
            Toggle("Transaction link", isOn: $hasTransactionLink)
            Toggle("Right to left", isOn: $isRightToLeft)

            counter("Explore taps", exploreTapCount)
            counter("Share taps", shareTapCount)
        }
        .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
    }

    func counter(_ title: String, _ value: Int) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(value)")
        }
    }
}

// MARK: - State

private extension EarnWithdrawalResultDemoView {
    var state: EarnWithdrawalResultContentView.StateModel {
        let preview = EarnWithdrawalResultContentView.StateModel.preview(
            status: isInProgress ? .inProgress : .withdrawn,
            withdrawalPeriod: isLendingOnAave ? "Usually instant" : "Up to 48 hours"
        )

        return EarnWithdrawalResultContentView.StateModel(
            status: preview.status,
            title: preview.title,
            summary: preview.summary,
            withdrawalPeriod: preview.withdrawalPeriod,
            fee: preview.fee,
            hasTransactionLink: hasTransactionLink
        )
    }

    func handle(_ action: EarnWithdrawalResultContentView.Action) {
        switch action {
        case .explore: exploreTapCount += 1
        case .share: shareTapCount += 1
        case .done: isPresented = false
        }
    }
}
