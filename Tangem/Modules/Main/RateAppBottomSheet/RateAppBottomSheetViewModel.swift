//
//  RateAppBottomSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

final class RateAppBottomSheetViewModel: ObservableObject, Identifiable {
    typealias RateAppInteraction = (_ result: RateAppResponse) -> Void

    private let onInteraction: RateAppInteraction
    private var isDismissInteractionAllowed = true

    init(onInteraction: @escaping RateAppInteraction) {
        self.onInteraction = onInteraction
    }

    deinit {
        if isDismissInteractionAllowed {
            onInteraction(.dismissed)
        }
    }

    func onRateAppSheetPositiveResponse() {
        isDismissInteractionAllowed = false
        onInteraction(.positive)
    }

    func onRateAppSheetNegativeResponse() {
        isDismissInteractionAllowed = false
        onInteraction(.negative)
    }
}
