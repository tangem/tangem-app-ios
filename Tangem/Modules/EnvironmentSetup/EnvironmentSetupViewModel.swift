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

    @Published var isTestnet: Bool
    @Published var toggles: [FeatureToggleViewModel]

    @Published var alert: AlertBinder?

    // MARK: - Dependencies

    private var bag: Set<AnyCancellable> = []

    init() {
        isTestnet = EnvironmentProvider.shared.isTestnet
        toggles = FeatureToggle.allCases.map { toggle in
            FeatureToggleViewModel(
                toggle: toggle,
                isActive: Binding<Bool> {
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

        bind()
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

private extension EnvironmentSetupViewModel {
    func bind() {
        $isTestnet
            .sink { EnvironmentProvider.shared.isTestnet = $0 }
            .store(in: &bag)
    }
}
