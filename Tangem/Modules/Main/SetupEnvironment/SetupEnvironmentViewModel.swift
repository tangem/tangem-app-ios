//
//  SetupEnvironmentViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class SetupEnvironmentViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var isTestnet: Bool
    @Published var toggles: [FeatureToggleViewModel]
    
    // MARK: - Dependencies
    
    private var bag: Set<AnyCancellable> = []

    init() {
        isTestnet = EnvironmentStorage.isTestnet
        toggles = FeatureToggle.allCases.map { toggle in
            FeatureToggleViewModel(
                toggle: toggle,
                isActive: Binding<Bool> {
                    EnvironmentStorage.integratedFeatures.contains(toggle.rawValue)
                } set: { isActive in
                    if isActive, !EnvironmentStorage.integratedFeatures.contains(toggle.rawValue) {
                        EnvironmentStorage.integratedFeatures.append(toggle.rawValue)
                    } else {
                        EnvironmentStorage.integratedFeatures.remove(toggle.rawValue)
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

private extension SetupEnvironmentViewModel {
    func bind() {
        $isTestnet
            .sink { EnvironmentStorage.isTestnet = $0 }
            .store(in: &bag)
    }
}
