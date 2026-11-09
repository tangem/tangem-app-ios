//
//  MCPAuthorizationDeeplinkResponder.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

final class MCPAuthorizationDeeplinkResponder: IncomingActionResponder {
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    func didReceiveIncomingAction(_ action: IncomingAction) -> Bool {
        guard case .navigation(.mcpAuthorization(let deeplink)) = action else {
            return false
        }

        return MainActor.assumeIsolated {
            guard let viewModel = MCPModuleFactory.makeConnectionRequestViewModel(userCode: deeplink.userCode) else {
                return false
            }

            floatingSheetPresenter.enqueue(sheet: viewModel)
            return true
        }
    }
}
