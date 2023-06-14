//
//  OrganizeTokensHeaderViewModel.swift
//  Tangem
//
//  Created by Andrey Fedorov on 06.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

final class OrganizeTokensHeaderViewModel: ObservableObject {
    @Published var isLeadingButtonSelected = true

    var leadingButtonTitle: String {
        return Localization.organizeTokensSortByBalance
    }

    @Published var isTrailingButtonSelected = true

    var trailingButtonTitle: String {
        return isTrailingButtonSelected
            ? Localization.organizeTokensGroup
            : Localization.organizeTokensUngroup
    }

    func onLeadingButtonTap() {
        isLeadingButtonSelected.toggle()
        // TODO: Andrey Fedorov - Add actual implementation (IOS-3461)
    }

    func onTrailingButtonTap() {
        isTrailingButtonSelected.toggle()
        // TODO: Andrey Fedorov - Add actual implementation (IOS-3461)
    }
}
