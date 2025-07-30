//
//  DefaultRowViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

class DefaultRowViewModel: ObservableObject, Identifiable {
    @Published private(set) var title: String
    @Published private(set) var detailsType: DetailsType?
    @Published private(set) var action: (() -> Void)?
    @Published private(set) var secondaryAction: (() -> Void)?
    private(set) var accessibilityIdentifier: String?

    init(
        title: String,
        detailsType: DetailsType? = .none,
        action: (() -> Void)? = nil,
        secondaryAction: (() -> Void)? = nil,
        accessibilityIdentifier: String? = nil
    ) {
        self.title = title
        self.detailsType = detailsType
        self.action = action
        self.secondaryAction = secondaryAction
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    func update(title: String) {
        self.title = title
    }

    func update(detailsType: DetailsType?) {
        self.detailsType = detailsType
    }

    func update(action: (() -> Void)? = nil) {
        self.action = action
    }

    func update(secondaryAction: (() -> Void)? = nil) {
        self.secondaryAction = secondaryAction
    }
}

extension DefaultRowViewModel {
    enum DetailsType: Hashable {
        case loadable(state: LoadableTextView.State)
        case text(_ string: String, sensitive: Bool = false)
        case loader
        case icon(_ image: ImageType)
        case badge(_ item: BadgeView.Item)
    }
}
