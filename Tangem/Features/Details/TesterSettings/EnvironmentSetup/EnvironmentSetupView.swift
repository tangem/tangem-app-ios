//
//  EnvironmentSetupView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils
import TangemAccessibilityIdentifiers

struct EnvironmentSetupView: View {
    @ObservedObject private var viewModel: EnvironmentSetupViewModel

    init(viewModel: EnvironmentSetupViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            DesignSystem.Color.bgPrimary.edgesIgnoringSafeArea(.all)

            ScrollViewReader { proxy in
                GroupedScrollView(contentType: .lazy(alignment: .center, spacing: 16)) {
                    if !viewModel.isSearching {
                        GroupedSection(viewModel.appSettingsTogglesViewModels) {
                            DefaultToggleRowView(viewModel: $0)
                        }

                        GroupedSection(viewModel.pickerViewModels) {
                            DefaultPickerRowView(viewModel: $0)
                        }

                        GroupedSection(viewModel.additionalSettingsViewModels) { viewModel in
                            DefaultRowView(viewModel: viewModel)
                        }
                    }

                    featureTogglesSection
                        .id(Constants.featureTogglesSectionId)

                    if !viewModel.isSearching {
                        surveySparrowControls

                        demoCardIdControls

                        appUidControls

                        fcmControls

                        walletIdControls
                    }
                }
                .interContentPadding(8)
                .scrollDismissesKeyboard(.immediately)
                .onChange(of: viewModel.searchText) { _ in
                    proxy.scrollTo(Constants.featureTogglesSectionId, anchor: .top)
                }
            }
        }
        .tangemSearchable(text: $viewModel.searchText, prompt: "Search feature toggles", placement: .bottom)
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .navigationBarTitle(Text("Environment setup"))
        .navigationBarItems(trailing: exitButton)
        .alert(item: $viewModel.alert) { $0.alert }
    }

    private var featureTogglesSection: some View {
        GroupedSection(viewModel.featureStateViewModels) { viewModel in
            FeatureStateRowView(viewModel: viewModel)
        } header: {
            DefaultHeaderView(viewModel.featureTogglesSectionTitle)
                .padding(.top, 12)
        } emptyContent: {
            Text("No feature toggles found")
                .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
        }
    }

    // [REDACTED_TODO_COMMENT]
    private var surveySparrowControls: some View {
        controlsSection("SurveySparrow demo token:") {
            textField("survey token", text: $viewModel.surveySparrowToken)

            fullWidthButton(
                "SurveySparrow demo classic",
                styleType: .primary,
                action: viewModel.handleSurveySparrowDemoClassicButtonTapped
            )

            fullWidthButton(
                "SurveySparrow demo chat",
                styleType: .primary,
                action: viewModel.handleSurveySparrowDemoClassicButtonTapped
            )

            fullWidthButton(
                "SurveySparrow demo NPS",
                styleType: .primary,
                action: viewModel.handleSurveySparrowDemoClassicButtonTapped
            )
        }
    }

    private var demoCardIdControls: some View {
        controlsSection("Demo card override") {
            textField("Demo card ID", text: $viewModel.forcedDemoCardId)

            Text(
                """
                Note that a restart is required for the override to take effect.

                **Warning**: when demo override is imposed on a regular card it still has all the amounts in the respective blockchain wallets and it is still possible to spend these money even though the displayed amount might be different
                """
            )
            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
        }
    }

    private var appUidControls: some View {
        controlsSection("Reset application UID") {
            VStack(spacing: 15) {
                valueText("UID: \(viewModel.applicationUid)")

                fullWidthButton(
                    "Reset application UID",
                    styleType: .secondary(.error),
                    action: viewModel.resetApplicationUID
                )
            }
        }
    }

    private var fcmControls: some View {
        controlsSection("FCM token") {
            copyableValueRow(title: "FCM token", value: viewModel.fcmToken)
        }
    }

    private var walletIdControls: some View {
        controlsSection("Wallet IDs") {
            VStack(spacing: 15) {
                ForEach(viewModel.walletIds) { wallet in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(wallet.name)
                            .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textPrimary)

                        copyableValueRow(title: "id", value: wallet.id)

                        copyableValueRow(title: "hash", value: wallet.hash)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func controlsSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(spacing: 10) {
            Text(title)
                .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)

            content()
        }
        .padding(.horizontal)
    }

    private func copyableValueRow(title: String, value: String) -> some View {
        HStack {
            valueText("\(title): \(value)")

            TangemUI.Button(icon: DesignSystem.Icons.Copy.regular20, accessibilityLabel: "Copy \(title)") {
                viewModel.copy(value)
            }
            .styleType(.ghost)
            .size(.x8)
        }
    }

    private func valueText(_ value: String) -> some View {
        Text(value)
            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
    }

    private func textField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
            .padding()
            .border(DesignSystem.Color.borderPrimary, width: 1)
    }

    private func fullWidthButton(
        _ label: String,
        styleType: TangemUI.Button.StyleType,
        action: @escaping () -> Void
    ) -> some View {
        TangemUI.Button(label: label, accessibilityLabel: nil, action: action)
            .styleType(styleType)
            .size(.x12)
            .horizontalLayout(.infinity)
    }

    private var exitButton: some View {
        SwiftUI.Button("Exit", action: viewModel.showExitAlert)
            .disableAnimations()
    }
}

// MARK: - Constants

private extension EnvironmentSetupView {
    enum Constants {
        static let featureTogglesSectionId = "featureTogglesSection"
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        EnvironmentSetupView(viewModel: EnvironmentSetupViewModel(coordinator: EnvironmentSetupRoutableMock()))
    }
}
