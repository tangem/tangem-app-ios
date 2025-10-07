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
    func fetchApy() async {
        do {
            let tokenInfo = try await manager.getYieldTokenInfo()
            apyLabelState = .loaded(text: String(format: "%.2f%%", NSDecimalNumber(decimal: tokenInfo.apy).doubleValue))
        } catch {
            apyLabelState = .noData
        }
    }

    func onTapAction() {
        navigationAction()
    }
}

extension YieldStatusViewModel {
    enum State: Equatable {
        case loading
        case active(isApproveRequired: Bool)
        case closing
    }
}
