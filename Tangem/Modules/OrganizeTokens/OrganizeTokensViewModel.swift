//
//  OrganizeTokensViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class OrganizeTokensViewModel: ObservableObject {
    let headerViewModel: OrganizeTokensHeaderViewModel

    @Published
    var sections: [OrganizeTokensListSectionViewModel]

    private unowned let coordinator: OrganizeTokensRoutable

    init(
        coordinator: OrganizeTokensRoutable
    ) {
        self.coordinator = coordinator
        headerViewModel = OrganizeTokensHeaderViewModel()
        sections = []
    }

    func onCancelButtonTap() {
        // [REDACTED_TODO_COMMENT]
    }

    func onApplyButtonTap() {
        // [REDACTED_TODO_COMMENT]
    }
}
