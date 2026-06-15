//
//  PushNotificationsMainView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct PushNotificationsMainView: View {
    @ObservedObject var viewModel: PushNotificationsMainViewModel

    /// Height-change animation is enabled only after the first state settles, so the initial
    /// appearance shows at full height (no "expanding upward") while `onboarding -> warning`
    /// transitions still animate the sheet height smoothly.
    @State private var isFrameUpdateAnimationEnabled = false

    var body: some View {
        ZStack {
            switch viewModel.viewState {
            case .onboarding(let viewModel):
                PushNotificationsPermissionRequestView(
                    viewModel: viewModel,
                    topInset: -32.0, // The mock-ups are messy, so this value is found by trial and error
                    buttonsAxis: .horizontal
                )
                .fixedSize(horizontal: false, vertical: true)
                // The shared request view keeps a 6pt bottom inset tuned for the legacy bottom sheet;
                // add 10pt here to reach the 16pt button-to-edge spacing used by the warning state.
                .padding(.bottom, 10.0)
                .transition(.content)

            case .warning(let viewModel):
                PushNotificationsWarningView(viewModel: viewModel)
                    .transition(.content)

            case .none:
                EmptyView()
            }
        }
        .task {
            // `.task` fires before `onAppear`, so the flag is armed slightly earlier in the appearance cycle.
            // Let cancellation (sheet disappearing) skip the assignment instead of mutating state on a gone view.
            do {
                try await Task.sleep(for: .seconds(Constants.frameAnimationActivationDelay))
                isFrameUpdateAnimationEnabled = true
            } catch {}
        }
        .onDisappear(perform: viewModel.onDismiss)
        .floatingSheetConfiguration { configuration in
            configuration.sheetBackgroundColor = Colors.Background.primary
            configuration.sheetFrameUpdateAnimation = isFrameUpdateAnimationEnabled ? .contentFrameUpdate : nil
            configuration.backgroundInteractionBehavior = .tapToDismiss
        }
    }
}

private extension PushNotificationsMainView {
    enum Constants {
        static let frameAnimationActivationDelay: TimeInterval = 0.6
    }
}

private extension Animation {
    static let contentFrameUpdate = Animation.curve(.easeInOutRefined, duration: 0.5)
}

private extension AnyTransition {
    static let content = AnyTransition.asymmetric(
        insertion: .opacity.animation(.curve(.easeInOutRefined, duration: 0.3).delay(0.2)),
        removal: .opacity.animation(.curve(.easeInOutRefined, duration: 0.3))
    )
}
