//
//  LearnViewModel.swift
//
//
//  Created by [REDACTED_AUTHOR]
//

import Combine
import SwiftUI

final class LearnViewModel: ObservableObject {
    // MARK: - ViewState

    // MARK: - Dependencies

    private unowned let coordinator: LearnRoutable

    init(
        coordinator: LearnRoutable
    ) {
        self.coordinator = coordinator
    }
}
