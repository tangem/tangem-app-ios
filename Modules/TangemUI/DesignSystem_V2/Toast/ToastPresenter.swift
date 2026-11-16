//
//  ToastPresenter.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import UIKit
import TangemUIUtils

@MainActor
public final class ToastPresenter {
    public static let shared = ToastPresenter(clock: ContinuousClock())

    private let clock: any Clock<Duration>
    private let stack = ToastStackModel()
    private var host: UIHostingController<ToastStackView>?
    private var container: ToastContainerView?
    private var timers: [UUID: Task<Void, Never>] = [:]
    private var voiceOverHolds: [UUID: Bool] = [:]
    private var voiceOverObserver: NSObjectProtocol?

    init(clock: any Clock<Duration>) {
        self.clock = clock
        observeVoiceOverStatus()
    }

    public func show(_ toast: ToastView) {
        guard let window = UIApplication.overlayWindow ?? UIApplication.mainWindow else {
            return
        }

        install(in: window)
        stack.topInset = window.safeAreaInsets.top

        let id = UUID()
        let reduceMotion = UIAccessibility.isReduceMotionEnabled
        let estimatedHeight = UIFontMetrics.default.scaledValue(for: ToastMetrics.minHeight)
        let model = ToastItemModel(
            reduceMotion: reduceMotion,
            startOffsetY: -(window.safeAreaInsets.top / 2 + ToastStackLayout.topOffset + estimatedHeight / 2)
        )
        let item = ToastStackItem(
            id: id,
            toast: toast,
            model: model,
            dismiss: ToastDismissAction { [weak self] in self?.dismiss(id: id) }
        )

        let holdsForVoiceOver = toast.action != nil
            && toast.isClosable
            && UIAccessibility.isVoiceOverRunning
            && window.rootViewController?.view.accessibilityViewIsModal != true

        model.onPresented = { [weak self] isMultiline in
            if holdsForVoiceOver, UIAccessibility.isVoiceOverRunning {
                self?.voiceOverHolds[id] = isMultiline
            } else {
                self?.startTimer(id: id, isMultiline: isMultiline)
            }
        }

        stack.insert(item, animated: !reduceMotion)
        UIAccessibility.post(notification: .announcement, argument: toast.label)
    }

    public func dismissAll() {
        stack.items.map(\.id).forEach(dismiss(id:))
    }
}

// MARK: - Private

private extension ToastPresenter {
    enum Timing {
        static let transition: Duration = .milliseconds(350)
        static let display: Duration = .milliseconds(2000)
        static let multilineDisplay: Duration = .milliseconds(3000)
    }

    func install(in window: UIWindow) {
        if let container, container.window === window {
            window.bringSubviewToFront(container)
            return
        }

        container?.removeFromSuperview()

        let host = UIHostingController(rootView: ToastStackView(stack: stack))
        host.safeAreaRegions = []
        host.view.backgroundColor = .clear
        host.view.frame = window.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let container = ToastContainerView(frame: window.bounds)
        container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.containsToast = { [stack] point in stack.containsToast(at: point) }
        container.addSubview(host.view)
        window.addSubview(container)

        self.host = host
        self.container = container
    }

    func observeVoiceOverStatus() {
        voiceOverObserver = NotificationCenter.default.addObserver(
            forName: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard !UIAccessibility.isVoiceOverRunning else { return }
                self?.releaseVoiceOverHolds()
            }
        }
    }

    func releaseVoiceOverHolds() {
        let holds = voiceOverHolds
        voiceOverHolds = [:]
        holds.forEach { id, isMultiline in startTimer(id: id, isMultiline: isMultiline) }
    }

    func startTimer(id: UUID, isMultiline: Bool) {
        let displayDuration = isMultiline ? Timing.multilineDisplay : Timing.display
        timers[id] = Task { [weak self, clock] in
            try? await clock.sleep(for: Timing.transition + displayDuration)
            guard !Task.isCancelled else { return }
            self?.dismiss(id: id)
        }
    }

    func dismiss(id: UUID) {
        guard let item = stack.items.first(where: { $0.id == id }), !item.model.isDismissing else {
            return
        }

        timers.removeValue(forKey: id)?.cancel()
        voiceOverHolds[id] = nil
        stack.frames[id] = nil
        item.model.dismiss()

        Task { [weak self, clock] in
            try? await clock.sleep(for: Timing.transition)
            self?.stack.remove(id: id, animated: !item.model.reduceMotion)
        }
    }
}

// MARK: - Container

private final class ToastContainerView: UIView {
    var containsToast: @MainActor (CGPoint) -> Bool = { _ in false }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        containsToast(convert(point, to: nil))
    }
}

// MARK: - Stack

enum ToastStackLayout {
    static let sideInset: CGFloat = 16
    static let topOffset: CGFloat = 44 + 24
    static let spacing: CGFloat = 8
}

struct ToastStackItem: Identifiable {
    let id: UUID
    let toast: ToastView
    let model: ToastItemModel
    let dismiss: ToastDismissAction
}

@MainActor
final class ToastStackModel: ObservableObject {
    @Published private(set) var items: [ToastStackItem] = []
    @Published var topInset: CGFloat = 0
    var frames: [UUID: CGRect] = [:]

    func insert(_ item: ToastStackItem, animated: Bool) {
        withAnimation(animated ? ToastAnimation.easeOutBack(duration: 0.35) : nil) {
            items.insert(item, at: 0)
        }
    }

    func remove(id: UUID, animated: Bool) {
        frames[id] = nil
        withAnimation(animated ? ToastAnimation.easeOutBack(duration: 0.35) : nil) {
            items.removeAll { $0.id == id }
        }
    }

    func containsToast(at point: CGPoint) -> Bool {
        frames.values.contains { $0.contains(point) }
    }
}

struct ToastStackView: View {
    @ObservedObject var stack: ToastStackModel

    var body: some View {
        VStack(spacing: ToastStackLayout.spacing) {
            ForEach(stack.items) { item in
                ToastStackItemView(item: item, model: item.model) { frame in
                    stack.frames[item.id] = frame
                }
                .transition(.identity)
            }
        }
        .padding(.top, stack.topInset + ToastStackLayout.topOffset)
        .padding(.horizontal, ToastStackLayout.sideInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

struct ToastStackItemView: View {
    let item: ToastStackItem
    @ObservedObject var model: ToastItemModel
    let onFrameChange: (CGRect) -> Void

    @ScaledMetric private var minHeight = ToastMetrics.minHeight

    var body: some View {
        item.toast
            .environment(\.toastDismissAction, item.dismiss)
            .environment(\.toastTransition, model.transition)
            .offset(y: model.offsetY)
            .allowsHitTesting(!model.isDismissing)
            .onGeometryChange(for: CGRect.self, of: { $0.frame(in: .global) }) { frame in
                guard !model.isDismissing else { return }
                onFrameChange(frame)
                model.present(size: frame.size, isMultiline: frame.height > minHeight + 0.5)
            }
    }
}

// MARK: - Item

@MainActor
final class ToastItemModel: ObservableObject {
    @Published private(set) var transition: ToastTransition
    @Published private(set) var offsetY: CGFloat
    @Published private(set) var isDismissing = false

    var onPresented: ((_ isMultiline: Bool) -> Void)?

    let reduceMotion: Bool
    private var isPresented = false

    init(reduceMotion: Bool, startOffsetY: CGFloat) {
        self.reduceMotion = reduceMotion

        if reduceMotion {
            transition = ToastTransition(isContentVisible: false, isSurfaceVisible: false, surfaceSize: nil)
            offsetY = 0
        } else {
            transition = ToastTransition(isContentVisible: false, isSurfaceVisible: false, surfaceSize: Self.collapsedSize)
            offsetY = startOffsetY
        }
    }

    func present(size: CGSize, isMultiline: Bool) {
        guard !isPresented else {
            if !reduceMotion, !isDismissing, transition.surfaceSize != size {
                transition.surfaceSize = size
            }
            return
        }

        isPresented = true
        show(size: size)
        onPresented?(isMultiline)
    }

    func dismiss() {
        isDismissing = true

        if reduceMotion {
            withAnimation(ToastAnimation.fade) {
                transition.isSurfaceVisible = false
                transition.isContentVisible = false
            }
            return
        }

        withAnimation(.timingCurve(0.3, -0.05, 0.65, -0.2, duration: 0.35)) {
            transition.surfaceSize = Self.dismissedSize
        }
        withAnimation(ToastAnimation.easeOutBack(duration: 0.3)) {
            transition.isContentVisible = false
        }
        withAnimation(ToastAnimation.easeOutBack(duration: 0.3).delay(0.05)) {
            transition.isSurfaceVisible = false
        }
    }

    private func show(size: CGSize) {
        if reduceMotion {
            withAnimation(ToastAnimation.fade) {
                transition.isSurfaceVisible = true
                transition.isContentVisible = true
            }
            return
        }

        withAnimation(ToastAnimation.easeOutBack(duration: 0.35)) {
            transition.surfaceSize = size
            offsetY = 0
        }
        withAnimation(ToastAnimation.easeOutBack(duration: 0.3).delay(0.05)) {
            transition.isSurfaceVisible = true
        }
        withAnimation(ToastAnimation.easeOutBack(duration: 0.25).delay(0.1)) {
            transition.isContentVisible = true
        }
    }

    private static let collapsedSize = CGSize(width: 120, height: 32)
    private static let dismissedSize = CGSize(width: 24, height: 24)
}

// MARK: - Animation

enum ToastAnimation {
    static let fade = Animation.easeInOut(duration: 0.3)

    static func easeOutBack(duration: TimeInterval) -> Animation {
        .timingCurve(0.4, 1.15, 0.8, 1, duration: duration)
    }
}
