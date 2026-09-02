//
//  ShtorkaProgressTracker.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import CoreGraphics
import TangemFoundation

final class ShtorkaProgressTracker: ObservableObject {
    private weak var state: ShtorkaState?

    private var collapsedHeight: CGFloat?
    private var fullHeight: CGFloat?
    private let samples = PassthroughSubject<Sample, Never>()
    private var bag = Set<AnyCancellable>()

    init() {
        bind()
    }

    func ingest(height: CGFloat, from state: ShtorkaState) {
        self.state = state

        guard height > 0 else {
            return
        }

        samples.send(Sample(height: height, size: state.size))
    }

    func reset() {
        // A sample debounced moments before the dismissal would otherwise land on top of the zero below.
        bag.removeAll()
        bind()

        state?.report(expansionProgress: 0)
    }

    private func bind() {
        samples
            .withWeakCaptureOf(self)
            .sink { tracker, sample in
                tracker.report(height: sample.height)
            }
            .store(in: &bag)

        samples
            .debounce(for: Constants.settleDelay, scheduler: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { tracker, sample in
                tracker.calibrate(with: sample)
                tracker.report(height: sample.height)
            }
            .store(in: &bag)
    }

    /// Detent heights change at runtime (a consumer re-measures its rows, the type size changes),
    /// so the latest settled sample wins over any earlier one.
    private func calibrate(with sample: Sample) {
        switch sample.size {
        case .collapsed: collapsedHeight = sample.height
        case .full: fullHeight = sample.height
        case .medium: break
        }
    }

    private func report(height: CGFloat) {
        let collapsedHeight = collapsedHeight ?? ShtorkaMetrics.collapsedHeight
        let fullHeight = fullHeight ?? ShtorkaMetrics.minimumRevealedHeight
        let travel = fullHeight - collapsedHeight

        guard travel > 0 else {
            return
        }

        state?.report(expansionProgress: clamp((height - collapsedHeight) / travel, min: 0, max: 1))
    }
}

// MARK: - Sample

private extension ShtorkaProgressTracker {
    struct Sample {
        let height: CGFloat
        let size: ShtorkaSize
    }
}

// MARK: - Constants

private extension ShtorkaProgressTracker {
    enum Constants {
        /// Samples arrive on every frame of a drag or a settle animation; a sample that no other
        /// follows for this long is the sheet resting at a detent, and only those calibrate.
        static let settleDelay: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(150)
    }
}
