//
//  StoryTapNavigationView.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

/// Single `DragGesture(minimumDistance: 0)` so tap, hold-to-pause and swipe-down can't race
/// each other: a hold pauses until the finger lifts, and its release never counts as a tap.
/// The touch itself is tracked via `@GestureState` because it auto-resets when the system
/// cancels the gesture — `onEnded` never fires on cancellation, which would otherwise leave
/// the story paused forever and swallow the next tap.
struct StoryTapNavigationView: View {
    let onBackward: () -> Void
    let onForward: () -> Void
    let onHoldChanged: (Bool) -> Void
    let onSwipeDown: () -> Void

    @GestureState private var isTouchDown = false
    @State private var holdTask: Task<Void, Never>?
    @State private var isHoldActive = false
    @State private var didHold = false

    var body: some View {
        GeometryReader { proxy in
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .updating($isTouchDown) { _, state, _ in state = true }
                        .onEnded { value in handleTouchEnd(value: value, width: proxy.size.width) }
                )
        }
        .ignoresSafeArea()
        .onChange(of: isTouchDown) { touching in
            if touching {
                beginHoldRecognition()
            } else {
                endHoldIfNeeded()
            }
        }
    }

    private func beginHoldRecognition() {
        didHold = false
        holdTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: Constants.holdRecognitionNanos)
            guard !Task.isCancelled else { return }
            didHold = true
            setHold(true)
        }
    }

    /// Runs on both normal release (alongside `onEnded`) and system cancellation (where
    /// `onEnded` never fires); resumes exactly once whichever path gets there first.
    private func endHoldIfNeeded() {
        holdTask?.cancel()
        holdTask = nil
        setHold(false)
    }

    private func setHold(_ active: Bool) {
        guard isHoldActive != active else { return }
        isHoldActive = active
        onHoldChanged(active)
    }

    private func handleTouchEnd(value: DragGesture.Value, width: CGFloat) {
        endHoldIfNeeded()

        let isSwipeDown = value.translation.height > Constants.swipeDownThreshold

        if didHold {
            if isSwipeDown {
                onSwipeDown()
            }
            return
        }

        if isSwipeDown {
            onSwipeDown()
            return
        }

        guard abs(value.translation.width) < Constants.tapSlop,
              abs(value.translation.height) < Constants.tapSlop else { return }

        if value.startLocation.x < width / 3 {
            onBackward()
        } else {
            onForward()
        }
    }

    private enum Constants {
        static let holdRecognitionNanos: UInt64 = 200_000_000
        static let swipeDownThreshold: CGFloat = 80
        static let tapSlop: CGFloat = 10
    }
}
