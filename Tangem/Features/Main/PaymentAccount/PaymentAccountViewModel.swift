//
//  PaymentAccountViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

protocol PaymentAccountViewModel: ObservableObject {
    var state: PaymentAccountViewState { get }
    var subtitle: String { get }
    var avatarImage: Image { get }
    var title: String { get }
    var currencySymbol: String { get }

    func userDidTapView()
}
