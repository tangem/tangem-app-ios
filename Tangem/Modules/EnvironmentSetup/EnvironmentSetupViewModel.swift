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
    
    // MARK: - Dependencies
    
    private var bag: Set<AnyCancellable> = []

    init() {
        isTestnet = EnvironmentProvider.isTestnet
        toggles = FeatureToggle.allCases.map { toggle in
            FeatureToggleViewModel(
                toggle: toggle,
                isActive: Binding<Bool> {
                    EnvironmentProvider.integratedFeatures.contains(toggle.rawValue)
                } set: { isActive in
                    if isActive, !EnvironmentProvider.integratedFeatures.contains(toggle.rawValue) {
                        EnvironmentProvider.integratedFeatures.append(toggle.rawValue)
                    } else {
                        EnvironmentProvider.integratedFeatures.remove(toggle.rawValue)
                    }
                }
            )
        }
        
        bind()
    }
    
    func turnOff() {
        exit(1)
    }
}

private extension EnvironmentSetupViewModel {
    func bind() {
        $isTestnet
            .sink { EnvironmentProvider.isTestnet = $0 }
            .store(in: &bag)
    }
}
