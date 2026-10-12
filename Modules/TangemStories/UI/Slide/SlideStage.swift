//
//  SlideStage.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct SlideStage: View {
    @ObservedObject var vm: SlidePlayerViewModel
    /// Hidden window neighbours sit in `.preparing`; animating a spinner for them is wasted work.
    var isVisible = true
    @State private var showsBufferingSpinner = false

    var body: some View {
        ZStack {
            SlideContentView(vm: vm)

            if isVisible, vm.state == .preparing || showsBufferingSpinner {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .task(id: vm.state) {
            // Short stalls recover on their own; flashing a spinner for them reads as a glitch.
            guard vm.state == .buffering else {
                showsBufferingSpinner = false
                return
            }
            try? await Task.sleep(nanoseconds: Constants.bufferingSpinnerDelayNanos)
            if !Task.isCancelled {
                showsBufferingSpinner = true
            }
        }
    }

    private enum Constants {
        static let bufferingSpinnerDelayNanos: UInt64 = 300_000_000
    }
}
