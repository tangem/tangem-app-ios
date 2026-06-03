//
//  KeyboardAutoHideModifier.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

public extension View {
    /// Automatically hides the keyboard after a period of inactivity.
    /// - Parameters:
    ///   - isActive: FocusState binding to keyboard visibility state.
    ///   - onInput: Publisher that emits on user input (resets the timer).
    ///   - delay: Time of inactivity before hiding the keyboard. Default is 5 seconds.
    func keyboardAutoHide<P: Publisher>(
        isActive: FocusState<Bool>.Binding,
        onInput inputPublisher: P,
        delay: Duration = .seconds(5)
    ) -> some View where P.Failure == Never {
        modifier(
            KeyboardAutoHideModifier(
                isActive: Binding(
                    get: { isActive.wrappedValue },
                    set: { isActive.wrappedValue = $0 }
                ),
                inputStream: inputPublisher.asyncStream,
                delay: delay
            )
        )
    }
}

private struct KeyboardAutoHideModifier<Output>: ViewModifier {
    @State private var autoHideTask: Task<Void, Never>?

    @Binding var isActive: Bool

    let inputStream: AsyncStream<Output>
    let delay: Duration

    func body(content: Content) -> some View {
        content
            .task(id: isActive, cancelAutoHideIfNeeded)
            .task(handleInput)
            .onDisappear(perform: cancelAutoHide)
    }
}

private extension KeyboardAutoHideModifier {
    // MARK: - Private logic

    @MainActor
    func handleInput() async {
        for await _ in inputStream {
            guard isActive else { continue }
            scheduleAutoHide()
        }
    }

    @MainActor
    func cancelAutoHideIfNeeded() {
        guard isActive else { return cancelAutoHide() }
        scheduleAutoHide()
    }

    @MainActor
    func cancelAutoHide() {
        autoHideTask?.cancel()
        autoHideTask = nil
    }

    @MainActor
    func scheduleAutoHide() {
        autoHideTask?.cancel()
        autoHideTask = Task { @MainActor in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            isActive = false
        }
    }
}

// MARK: - Private helper

private extension Publisher where Failure == Never {
    var asyncStream: AsyncStream<Output> {
        AsyncStream { continuation in
            let cancellable = sink(
                receiveCompletion: { _ in continuation.finish() },
                receiveValue: { continuation.yield($0) }
            )
            continuation.onTermination = { _ in cancellable.cancel() }
        }
    }
}
