//
//  MainScreenPromoSheetManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

protocol MainScreenPromoSheetManager: AnyObject {
    var id: String { get }
    var experimentKey: ExperimentFeatureFlagKey { get }
    var statePublisher: AnyPublisher<MainScreenPromoSheetManagerState, Never> { get }

    func canHandlePresentation(_ settings: MainScreenPromoSheetPresentationSettings) -> Bool
    func presentSheet(experimentVariant: String?) -> AnyPublisher<Void, Never>?
    func logShown()
    func logSkipped(_ reason: MainScreenPromoSheetSkipReason)
}

struct MainScreenPromoSheetPresentationSettings {
    let isOpenedFromLink: Bool
}

enum MainScreenPromoSheetManagerState {
    case preparing
    case ready
    case unavailable(MainScreenPromoSheetSkipReason)
}

enum MainScreenPromoSheetSkipReason {
    case dataNotReady
    case noEligibleContent
    case variantNotReady
}
