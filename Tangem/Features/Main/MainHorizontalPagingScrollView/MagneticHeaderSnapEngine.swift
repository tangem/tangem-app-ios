//
//  MagneticHeaderSnapEngine.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// State machine deciding when the collapsing main header magnetically snaps to an edge. The view feeds
/// it raw scroll events and executes the `Command`s it emits; it never decides *whether* to snap, only *how*.
final class MagneticHeaderSnapEngine {
    enum HeaderAnchor: Equatable {
        case top
        case bottom
    }

    /// Measured in the same `.global` space as the fed offset.
    struct Layout: Equatable {
        let safeAreaInsetsTop: CGFloat
        let fullHeaderHeight: CGFloat
    }

    enum Command: Equatable {
        case snap(HeaderAnchor)
        case scheduleSettle
        case cancelSettle
    }

    enum Phase: Equatable {
        case idle
        case dragging
        case flickSnapped
        case settling
    }

    private(set) var phase: Phase = .idle

    private var lastSampleOffsetY: CGFloat?
    private var lastSampleTime: CFTimeInterval = 0
    private var velocityY: CGFloat = 0

    // MARK: - Events

    func dragBegan() -> Command? {
        let wasSettling = phase == .settling
        phase = .dragging
        resetVelocity()
        return wasSettling ? .cancelSettle : nil
    }

    func dragEnded() -> Command? {
        switch phase {
        case .dragging:
            phase = .settling
            return .scheduleSettle
        case .flickSnapped, .settling, .idle:
            phase = .idle
            return nil
        }
    }

    func offsetChanged(_ offsetY: CGFloat, at time: CFTimeInterval, layout: Layout) -> Command? {
        updateVelocity(offsetY: offsetY, time: time)

        guard phase == .dragging, let anchor = flickAnchor(offsetY: offsetY, layout: layout) else {
            return nil
        }

        phase = .flickSnapped
        return .snap(anchor)
    }

    func settleFired(offsetY: CGFloat, layout: Layout) -> Command? {
        guard phase == .settling else {
            return nil
        }

        phase = .idle

        guard let anchor = settleAnchor(offsetY: offsetY, layout: layout) else {
            return nil
        }

        return .snap(anchor)
    }

    // MARK: - Decisions

    private func flickAnchor(offsetY: CGFloat, layout: Layout) -> HeaderAnchor? {
        // `offsetY` decreases as the header collapses, so the partial zone sits between fully shown and fully hidden.
        let headerIsPartiallyCollapsed = offsetY < layout.safeAreaInsetsTop
            && offsetY > layout.safeAreaInsetsTop - layout.fullHeaderHeight

        let speed = abs(velocityY)

        guard headerIsPartiallyCollapsed,
              speed >= Tuning.flickVelocityThreshold,
              speed < Tuning.maxSnapVelocity else {
            return nil
        }

        // Negative velocity heads toward hidden (`.bottom`), positive toward shown (`.top`).
        return velocityY < 0 ? .bottom : .top
    }

    private func settleAnchor(offsetY: CGFloat, layout: Layout) -> HeaderAnchor? {
        let headerMaxY = offsetY + layout.fullHeaderHeight
        let screenTop = layout.safeAreaInsetsTop

        guard screenTop > offsetY, screenTop < headerMaxY else {
            return nil
        }

        let pastMidpoint = (screenTop - offsetY) > layout.fullHeaderHeight / 2
        return pastMidpoint ? .bottom : .top
    }

    // MARK: - Velocity

    private func updateVelocity(offsetY: CGFloat, time: CFTimeInterval) {
        defer {
            lastSampleOffsetY = offsetY
            lastSampleTime = time
        }

        guard let lastSampleOffsetY, time > lastSampleTime else {
            return
        }

        velocityY = (offsetY - lastSampleOffsetY) / CGFloat(time - lastSampleTime)
    }

    private func resetVelocity() {
        lastSampleOffsetY = nil
        velocityY = 0
    }

    private enum Tuning {
        /// Below this the gesture is a slow drag and falls into the soft settle snap.
        static let flickVelocityThreshold: CGFloat = 1500
        /// At or above this the gesture is a deliberate long scroll: no magnet, scroll freely.
        static let maxSnapVelocity: CGFloat = 2500
    }
}
