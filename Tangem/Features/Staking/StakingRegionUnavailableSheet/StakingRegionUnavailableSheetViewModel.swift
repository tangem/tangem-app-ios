//
//  StakingRegionUnavailableSheetViewModel.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization
import TangemUI

protocol StakingRegionUnavailableSheetRoutable: AnyObject {
    func closeStakingRegionUnavailableSheet()
}

final class StakingRegionUnavailableSheetViewModel: FloatingSheetContentViewModel {
    var title: String { Localization.commonStaking }
    var subtitle: String { Localization.stakingErrorUnavailableRegionDescription }
    var primaryButtonSettings: MainButton.Settings {
        MainButton.Settings(title: Localization.commonClose, action: close)
    }

    private weak var coordinator: (any StakingRegionUnavailableSheetRoutable)?

    init(coordinator: any StakingRegionUnavailableSheetRoutable) {
        self.coordinator = coordinator
    }

    func close() {
        coordinator?.closeStakingRegionUnavailableSheet()
    }
}
