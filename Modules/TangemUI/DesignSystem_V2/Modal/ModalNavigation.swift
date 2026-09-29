//
//  ModalNavigation.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct ModalNavigation {
    let title: String
    let subtitle: String?
    let leading: TopNavigation.LeadingPolicy
    let actions: TopNavigation.Actions?
    let onClose: (() -> Void)?
}
