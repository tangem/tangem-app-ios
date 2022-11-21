//
//  EnvironmentSetupViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class EnvironmentSetupViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var appSettingsTogglesViewModels: [DefaultToggleRowViewModel]
    @Published var togglesViewModels: [DefaultToggleRowViewModel]

    @Published var alert: AlertBinder?

    // MARK: - Dependencies

    private var bag: Set<AnyCancellable> = []

    init() {
        appSettingsTogglesViewModels = [
            DefaultToggleRowViewModel(
                title: "Use testnet",
                isOn: Binding<Bool>(get: { EnvironmentProvider.shared.isTestnet },
                                    set: { EnvironmentProvider.shared.isTestnet = $0 })
            ),
            DefaultToggleRowViewModel(
                title: "Use dev API",
                isOn: Binding<Bool>(get: { EnvironmentProvider.shared.useDevApi },
                                    set: { EnvironmentProvider.shared.useDevApi = $0 })
            ),
        ]

        togglesViewModels = FeatureToggle.allCases.map { toggle in
            DefaultToggleRowViewModel(
                title: toggle.name,
                isOn: Binding<Bool> {
                    EnvironmentProvider.shared.availableFeatures.contains(toggle)
                } set: { isActive in
                    if isActive {
                        EnvironmentProvider.shared.availableFeatures.insert(toggle)
                    } else {
                        EnvironmentProvider.shared.availableFeatures.remove(toggle)
                    }
                }
            )
        }
    }

    func showExitAlert() {
        let alert = Alert(
            title: Text("Are you sure you want to exit the app?"),
            primaryButton: .destructive(Text("Exit"), action: { exit(1) }),
            secondaryButton: .cancel()
        )
        self.alert = AlertBinder(alert: alert)
    }
}
