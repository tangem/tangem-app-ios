//
//  YieldStatusViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI
import Combine

final class YieldStatusViewModel: ObservableObject {
    @Published
    private(set) var apyLabelState: LoadableTextView.State = .loading

    @Published
    private(set) var state: State

    private let navigationAction: () -> Void

    // MARK: - Dependencies

    private let manager: YieldModuleManager

    init(state: State, manager: YieldModuleManager, navigationAction: @escaping () -> Void) {
        self.state = state
        self.manager = manager
        self.navigationAction = navigationAction
    }

    @MainActor
    func fetchApy() async {}

    func onTapAction() {
        navigationAction()
    }
}

extension YieldStatusViewModel {
    enum State: Equatable {
        case loading
        case active(isApproveRequired: Bool, hasUndepositedAmounts: Bool)
        case closing
    }
}
