//
//  ReferralViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Combine

class ReferralViewModel: ObservableObject {

    @Published var isLoading: Bool = true

    private let coordinator: ReferralRoutable

    init(coordinator: ReferralRoutable) {
        self.coordinator = coordinator
    }
}
