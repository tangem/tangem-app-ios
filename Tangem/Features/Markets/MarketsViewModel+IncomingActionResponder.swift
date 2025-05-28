//
//  MarketsViewModel+IncomingActionResponder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

extension MarketsViewModel: IncomingActionResponder {
    func didReceiveIncomingAction(_ action: IncomingAction) -> Bool {
        guard let handler = navigationActionHandler else {
            return false
        }

        return handler.routeIncommingAction(action)
    }
}
