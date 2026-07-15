//
//  StatusBannerDemoView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct StatusBannerDemoView: View {
    @State private var status: TransactionDetailsStatusBannerViewData?

    var body: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 24)
                .fill(DesignSystem.Color.bgTertiary)
                .frame(height: 120)
                .overlay { Text(verbatim: "Token / pair card").style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textTertiary) }

            if let status {
                TransactionDetailsStatusBannerView(data: status)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            controls
                .padding(.top, 16)
        }
        .padding(16)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
    }

    private var controls: some View {
        VStack(spacing: 8) {
            Button("▶︎ Play swap flow", action: playFlow)
            Button("In progress") { set(.init(kind: .inProgress, title: "Awaiting funds")) }
            Button("Success (auto-hide)") { showSuccess() }
            Button("Failed") { set(.init(kind: .warning, title: "Failed", subtitle: "Visit provider's website to refund your money")) }
            Button("Verification required") { set(.init(kind: .attention, title: "Verification required", subtitle: "Visit provider's website to refund your money")) }
            Button("Hide") { set(nil) }
        }
        .buttonStyle(.bordered)
    }

    private func set(_ value: TransactionDetailsStatusBannerViewData?) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { status = value }
    }

    private func showSuccess() {
        set(.init(kind: .success, title: "Funds received"))
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            set(nil)
        }
    }

    private func playFlow() {
        Task { @MainActor in
            set(.init(kind: .inProgress, title: "Awaiting funds"))
            try? await Task.sleep(for: .seconds(1.5))
            set(.init(kind: .inProgress, title: "Deposit confirmed"))
            try? await Task.sleep(for: .seconds(1.5))
            showSuccess()
        }
    }
}
