//
//  StoryPlayerViewModel.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

@MainActor
public final class StoryPlayerViewModel: ObservableObject {
    public let story: StoryV2

    @Published public private(set) var currentIndex: Int = 0
    @Published public private(set) var current: SlidePlayerViewModel

    private let onFinished: (_ exitReason: StoryExitReason, _ action: StoryActionV2?) -> Void

    /// Prepared slides kept around the active one: [i-1, i, i+1].
    private var window: [Int: SlidePlayerViewModel] = [:]

    private var hasStarted = false
    private var firstLoopDone = false

    public init(
        story: StoryV2,
        onFinished: @escaping (_ exitReason: StoryExitReason, _ action: StoryActionV2?) -> Void
    ) {
        precondition(!story.slides.isEmpty, "StoryPlayerViewModel requires a story with at least one slide")
        self.story = story
        self.onFinished = onFinished

        let first = SlidePlayerViewModel(slide: story.slides[0])
        window[0] = first
        current = first
    }

    // MARK: - Lifecycle

    /// Kick off playback of the first slide. Idempotent — safe to call from view's `onAppear`.
    public func start() {
        guard !hasStarted else { return }
        hasStarted = true
        activate(index: 0)
    }

    // MARK: - Controls

    public func tapForward() {
        advanceOrFinish()
    }

    public func tapBackward() {
        if currentIndex > 0 {
            activate(index: currentIndex - 1)
        } else {
            current.restart()
        }
    }

    public func pause() { current.pause() }
    public func resume() { current.resume() }

    public func closeButtonTapped() { finalize(exitReason: .closeButton, action: nil) }
    public func swipeDown() { finalize(exitReason: .swipeDown, action: nil) }
    public func actionTapped(_ action: StoryActionV2) { finalize(exitReason: .action, action: action) }

    // MARK: - Navigation

    private func activate(index: Int) {
        currentIndex = index
        refreshWindow(around: index)

        let vm = window[index] ?? makePrepared(at: index)
        vm.hapticsEnabled = !firstLoopDone
        vm.onCompleted = { [weak self] in self?.advanceOrFinish() }
        current = vm

        vm.play()
    }

    private func refreshWindow(around index: Int) {
        let wanted = Set([index - 1, index, index + 1].filter { story.slides.indices.contains($0) })

        // Mutating a dictionary during its own iteration is undefined in Swift — snapshot keys first.
        let stale = window.keys.filter { !wanted.contains($0) }
        for idx in stale {
            window[idx]?.teardown()
            window[idx] = nil
        }

        for idx in wanted where window[idx] == nil {
            _ = makePrepared(at: idx)
        }

        for (idx, vm) in window where idx != index {
            vm.rewindToPrepared()
        }
    }

    @discardableResult
    private func makePrepared(at index: Int) -> SlidePlayerViewModel {
        let vm = SlidePlayerViewModel(slide: story.slides[index])
        vm.prepare()
        window[index] = vm
        return vm
    }

    private func advanceOrFinish() {
        if currentIndex < story.slides.count - 1 {
            activate(index: currentIndex + 1)
        } else {
            handleEndReached()
        }
    }

    private func handleEndReached() {
        switch effectiveEndBehavior {
        case .finish:
            finalize(exitReason: .completed, action: story.actions.first)
        case .loop:
            firstLoopDone = true
            activate(index: 0)
        }
    }

    /// `.loop` is only safe when at least one slide surfaces an exit button; otherwise fall back to `.finish`.
    /// A slide's effective actions are `slide.actions ?? story.actions` — a slide that overrides with `[]`
    /// explicitly hides the story-level button on that slide.
    private var effectiveEndBehavior: EndBehavior {
        guard story.endBehavior == .loop else { return story.endBehavior }
        let hasExitButton = story.slides.contains { !($0.actions ?? story.actions).isEmpty }
        return hasExitButton ? .loop : .finish
    }

    private func finalize(exitReason: StoryExitReason, action: StoryActionV2?) {
        teardownWindow()
        onFinished(exitReason, action)
    }

    private func teardownWindow() {
        for vm in window.values {
            vm.teardown()
        }
        window.removeAll()
    }
}
