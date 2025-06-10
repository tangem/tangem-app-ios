//
//  ActionButtonsChooseTokenViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

final class ActionButtonsChooseTokenViewModel: ObservableObject {
    var title: String {
        switch field {
        case .source: Localization.swappingFromTitle
        case .destination: Localization.swappingToTitle
        }
    }

    var description: String {
        switch field {
        case .source: Localization.actionButtonsYouWantToSwap
        case .destination: Localization.actionButtonsYouWantToReceive
        }
    }

    let field: Field

    init(field: Field) {
        self.field = field
    }
}

extension ActionButtonsChooseTokenViewModel {
    enum Field {
        case source
        case destination
    }
}
