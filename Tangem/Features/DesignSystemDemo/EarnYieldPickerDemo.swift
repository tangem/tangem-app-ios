//
//  EarnYieldPickerDemo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

struct EarnYieldPickerDemoView: View {
    @StateObject private var coordinator = EarnYieldPickerDemoCoordinator()
    @State private var hasFunds = true
    @State private var isRightToLeft = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Toggle("Has ETH", isOn: $hasFunds)
                Toggle("Right to left", isOn: $isRightToLeft)

                SwiftUI.Button("Open picker") {
                    coordinator.open(hasFunds: hasFunds)
                }

                HStack {
                    Text("Last action")
                    Spacer()
                    Text(coordinator.lastAction)
                }
            }
            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
            .padding(16)
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
        .navigationTitle("Earn yield picker")
        .fullScreenCover(isPresented: isPickerPresented) {
            if let picker = coordinator.picker {
                NavigationStack {
                    EarnYieldPickerView(viewModel: picker)
                }
                .environment(\.layoutDirection, isRightToLeft ? .rightToLeft : .leftToRight)
            }
        }
    }

    private var isPickerPresented: Binding<Bool> {
        Binding(
            get: { coordinator.picker != nil },
            set: { isPresented in
                if !isPresented {
                    coordinator.picker = nil
                }
            }
        )
    }
}

// MARK: - Coordinator

private final class EarnYieldPickerDemoCoordinator: ObservableObject, EarnYieldPickerRoutable {
    @Published var picker: EarnYieldPickerViewModel?
    @Published private(set) var lastAction = "None"

    @MainActor
    func open(hasFunds: Bool) {
        picker = EarnYieldPickerViewModel(
            products: [.pooledStakingPreview, .lendingOnAavePreview],
            selectedProductID: .lendingOnAave,
            balanceProvider: NFTSendFixedBalanceProvider(
                tokenItem: .blockchain(.init(.ethereum(testnet: false), derivationPath: nil)),
                fixedValue: hasFunds ? 1 : 0
            ),
            currencyCode: AppSettings.shared.selectedCurrencyCode,
            coordinator: self
        )
    }

    func openStartEarning(for product: EarnYieldPickerProduct) {
        lastAction = "Start earning: \(product.name)"
    }

    func openAddFunds() {
        lastAction = "Add funds"
    }

    func openIncentiveInfo(for product: EarnYieldPickerProduct) {
        lastAction = "Incentive info: \(product.name)"
    }

    func openURL(_ url: URL) {
        lastAction = url.absoluteString
    }

    func dismissYieldPicker() {
        picker = nil
    }
}
