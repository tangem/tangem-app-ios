//
//  OrganizeTokensDragAndDropController+AuxiliaryTypes.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum OrganizeTokensDragAndDropControllerListViewKind {
    case cell
    case sectionHeader
}

enum OrganizeTokensDragAndDropControllerAutoScrollDirection {
    case top
    case bottom
}

enum OrganizeTokensDragAndDropControllerAutoScrollStatus {
    case active(direction: OrganizeTokensDragAndDropControllerAutoScrollDirection)
    case inactive

    var isActive: Bool {
        if case .active = self {
            return true
        }
        return false
    }
}
