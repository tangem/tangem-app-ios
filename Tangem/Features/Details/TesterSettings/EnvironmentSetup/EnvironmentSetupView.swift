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
                GroupedSection(viewModel.appSettingsTogglesViewModels) {
                    DefaultToggleRowView(viewModel: $0)
                }

                GroupedSection(viewModel.pickerViewModels) {
                    DefaultPickerRowView(viewModel: $0)
                }

                GroupedSection(viewModel.additionalSettingsViewModels) { viewModel in
                    DefaultRowView(viewModel: viewModel)
                }

                GroupedSection(viewModel.featureStateViewModels) { viewModel in
                    FeatureStateRowView(viewModel: viewModel)
                }

                demoCardIdControls

                appUidControls

                fcmControls
            }
            .interContentPadding(8)
        }
        .navigationBarTitle(Text("Environment setup"))
        .navigationBarItems(trailing: exitButton)
        .alert(item: $viewModel.alert) { $0.alert }
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

                Button("Reset application UID", action: viewModel.resetApplicationUID)
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

                    Button {
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

    private var exitButton: some View {
        Button("Exit", action: viewModel.showExitAlert)
            .disableAnimations()
    }
}

struct EnvironmentSetupView_Preview: PreviewProvider {
    static let viewModel = EnvironmentSetupViewModel(coordinator: EnvironmentSetupRoutableMock())

    static var previews: some View {
        NavigationStack {
            EnvironmentSetupView(viewModel: viewModel)
        }
    }
}
