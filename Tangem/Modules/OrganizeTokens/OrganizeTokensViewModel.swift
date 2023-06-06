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
    struct ListSection {
        var title: String
        var items: [ListItem]
    }

    struct ListItem {}
    
    let headerViewModel: OrganizeTokensHeaderViewModel

    @Published
    var sections: [ListSection]

    private unowned let coordinator: OrganizeTokensRoutable

    init(
        coordinator: OrganizeTokensRoutable
    ) {
        self.coordinator = coordinator
        headerViewModel = OrganizeTokensHeaderViewModel()
        sections = []
    }
}
