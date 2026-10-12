//
//  SegmentedControl+Phase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import CoreGraphics

extension SegmentedControl {
    /// The pill rises, carries the move, and only then relaxes, so the interaction is a sequence
    /// rather than a set of independent states.
    ///
    /// ```
    ///                  ┌────────────── relax ──────────────┐
    ///                  │                                   │
    /// idle ─ grab ─► rising ─ peak ─► held ─ commit ─► traveling ─ arrived
    ///                  │                │
    ///                commit             └─ commit, nothing moves ─► idle
    ///                  ▼
    ///             awaitingPeak ─ peak ─► traveling
    ///
    /// idle ─ tap on another segment ─► awaitingPeak ─ peak ─► traveling
    /// ```
    enum Phase: Equatable {
        case idle
        /// Finger down on the pill, the lift is still climbing.
        case rising(drag: CGFloat?)
        /// Finger down on the pill, the lift has reached its peak.
        case held(drag: CGFloat?)
        /// Committed while the lift was still climbing; the move starts once it peaks.
        case awaitingPeak(target: Tag, drag: CGFloat?)
        /// The move is running with the lift held; it relaxes when the pill arrives.
        case traveling
    }
}

extension SegmentedControl.Phase {
    var drag: CGFloat? {
        switch self {
        case .rising(let drag), .held(let drag), .awaitingPeak(_, let drag):
            return drag
        case .idle, .traveling:
            return nil
        }
    }

    var isEngaged: Bool {
        self != .idle
    }
}
