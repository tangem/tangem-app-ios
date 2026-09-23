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
            Colors.Background.secondary.edgesIgnoringSafeArea(.all)

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

                GroupedSection(viewModel.featureStateViewModels) { viewModel in
                    FeatureStateRowView(viewModel: viewModel)
                }

                if viewModel.isSearching, viewModel.featureStateViewModels.isEmpty {
                    Text("No feature toggles found")
                        .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
                        .padding(.top, 32)
                }

                if !viewModel.isSearching {
                    surveySparrowControls

                    demoCardIdControls

                    appUidControls

                    fcmControls

                    walletIdControls
                }
            }
            .interContentPadding(8)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            searchBar
        }
        .navigationBarTitle(Text("Environment setup"))
        .navigationBarItems(trailing: exitButton)
        .alert(item: $viewModel.alert) { $0.alert }
    }

    private var searchBar: some View {
        Search(text: $viewModel.searchText)
            .placeholder("Search feature toggles")
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
    }

    // [REDACTED_TODO_COMMENT]
    private var surveySparrowControls: some View {
        VStack(spacing: 16) {
            Text("SurveySparrow demo token:")
                .font(.headline)

            TextField("survey token", text: $viewModel.surveySparrowToken)
                .padding()
                .border(.gray, width: 1)

            MainButton(
                title: "SurveySparrow demo classic",
                action: viewModel.handleSurveySparrowDemoClassicButtonTapped
            )

            MainButton(
                title: "SurveySparrow demo chat",
                action: viewModel.handleSurveySparrowDemoClassicButtonTapped
            )

            MainButton(
                title: "SurveySparrow demo NPS",
                action: viewModel.handleSurveySparrowDemoClassicButtonTapped
            )
        }
        .padding(.horizontal)
    }

    private var demoCardIdControls: some View {
        VStack(spacing: 10) {
            Text("Demo card override")
                .font(.headline)
                .textCase(.uppercase)

            TextField("Demo card ID", text: $viewModel.forcedDemoCardId)
                .padding()
                .border(.gray, width: 1)

            Text(
                """
                Note that a restart is required for the override to take effect.

                **Warning**: when demo override is imposed on a regular card it still has all the amounts in the respective blockchain wallets and it is still possible to spend these money even though the displayed amount might be different
                """
            )
            .font(.footnote)
        }
        .padding(.horizontal)
    }

    private var appUidControls: some View {
        VStack(spacing: 10) {
            Text("Reset application UID")
                .font(.headline)

            VStack(spacing: 15) {
                HStack {
                    Text("UID: \(viewModel.applicationUid)")
                        .font(.footnote)
                }

                SwiftUI.Button("Reset application UID", action: viewModel.resetApplicationUID)
                    .foregroundColor(Color.red)
            }
        }
        .padding(.horizontal)
    }

    private var fcmControls: some View {
        VStack(spacing: 10) {
            Text("FCM token")
                .font(.headline)

            VStack(spacing: 15) {
                HStack {
                    Text("FCM token: \(viewModel.fcmToken)")
                        .font(.footnote)

                    SwiftUI.Button {
                        viewModel.copyField(\.fcmToken)
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(Color.blue)
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private var walletIdControls: some View {
        VStack(spacing: 10) {
            Text("Wallet IDs")
                .font(.headline)

            VStack(spacing: 15) {
                ForEach(viewModel.walletIds) { wallet in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(wallet.name)
                            .font(.footnote)
                            .bold()

                        walletIdRow(title: "id", value: wallet.id)

                        walletIdRow(title: "hash", value: wallet.hash)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.horizontal)
    }

    private func walletIdRow(title: String, value: String) -> some View {
        HStack {
            Text("\(title): \(value)")
                .font(.footnote)

            SwiftUI.Button {
                viewModel.copy(value)
            } label: {
                Image(systemName: "doc.on.doc")
                    .foregroundColor(Color.blue)
            }
        }
    }

    private var exitButton: some View {
        SwiftUI.Button("Exit", action: viewModel.showExitAlert)
            .disableAnimations()
    }
}

#Preview {
    NavigationStack {
        EnvironmentSetupView(viewModel: EnvironmentSetupViewModel(coordinator: EnvironmentSetupRoutableMock()))
    }
}
