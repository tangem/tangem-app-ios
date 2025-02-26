//
//  StoryView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

// [REDACTED_TODO_COMMENT]
struct StoryView: View {
    @ObservedObject var viewModel: StoryViewModel
    let pageViews: [StoryPageView]

    init(viewModel: StoryViewModel, pageViews: [StoryPageView]) {
        self.viewModel = viewModel
        self.pageViews = pageViews
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                preiOS18Gestures(proxy)
                pageViews[viewModel.visiblePageIndex]
                overlayElements
            }
            .modifier(if: Self.iOS18Available) { content in
                content
                    .gesture(longTapGesture)
                    .gesture(shortTapGesture(proxy))
            }
            .readGeometry(inCoordinateSpace: .global) { geometryInfo in
                let leftAnchor = geometryInfo.frame.minX / geometryInfo.size.width
                let isDuringTransition = leftAnchor != 0

                let viewEvent: StoryViewEvent = isDuringTransition
                    ? .viewInteractionPaused
                    : .viewInteractionResumed

                viewModel.handle(viewEvent: viewEvent)
            }
            .cubicRotationEffect(proxy)
            .preferredColorScheme(.dark)
        }
        .onAppear {
            viewModel.handle(viewEvent: .viewDidAppear)
        }
        .onDisappear {
            viewModel.handle(viewEvent: .viewDidDisappear)
        }
    }

    private var overlayElements: some View {
        VStack(spacing: .zero) {
            progressBar
            logoAndCloseButton
        }
        .padding(.top, 10)
    }

    private var progressBar: some View {
        HStack(alignment: .top, spacing: 4) {
            ForEach(Array(pageViews.indices), id: \.self, content: pageProgressView)
        }
        .frame(height: 2)
        .padding(.horizontal, 16)
    }

    private func pageProgressView(_ pageIndex: Int) -> some View {
        GeometryReader { proxy in
            Capsule()
                .fill(Colors.Icon.primary1.opacity(0.2))
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(Colors.Icon.primary1)
                        .frame(width: pageProgressWidth(for: pageIndex, proxy: proxy))
                }
                .clipped()
        }
    }

    private func pageProgressWidth(for index: Int, proxy: GeometryProxy) -> CGFloat {
        return proxy.size.width * viewModel.pageProgress(for: index)
    }

    private var logoAndCloseButton: some View {
        HStack(alignment: .top, spacing: .zero) {
            tangemLogo
            Spacer(minLength: .zero)
            closeButton
        }
        .foregroundStyle(Colors.Icon.primary1)
        .padding(.top, 12)
    }

    private var tangemLogo: some View {
        Assets.newTangemLogo.image
            .padding(.leading, 16)
    }

    private var closeButton: some View {
        Button {
            viewModel.handle(viewEvent: .closeButtonTapped)
        } label: {
            Assets.close.image
                .resizable()
                .frame(width: 14, height: 14)
                .padding(.top, 2)
                .padding(.bottom, 16)
                .padding(.horizontal, 16)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // [REDACTED_USERNAME], this is a fix for iOS 18 gesture interference with ScrollView that is used under the hood in host view.
        .gesture(DragGesture(minimumDistance: 0))
    }

    private static var iOS18Available: Bool {
        if #available(iOS 18.0, *) {
            return true
        }

        return false
    }
}

// MARK: - Gestures

extension StoryView {
    private var longTapGesture: some Gesture {
        LongPressGesture(minimumDuration: Constants.longPressMinimumDuration)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .local))
            .onChanged { _ in
                viewModel.handle(viewEvent: .longTapPressed)
            }
            .onEnded { _ in
                viewModel.handle(viewEvent: .longTapEnded)
            }
    }

    private func shortTapGesture(_ proxy: GeometryProxy) -> some Gesture {
        TapGesture()
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .local))
            .onEnded { value in
                switch value {
                case .second(_, let drag):
                    handleShortTap(drag?.location ?? .zero, proxy: proxy)
                default:
                    break
                }
            }
    }

    @ViewBuilder
    private func preiOS18Gestures(_ proxy: GeometryProxy) -> some View {
        if !Self.iOS18Available {
            GestureRecognizerView(
                tapAction: { tapLocation in
                    handleShortTap(tapLocation, proxy: proxy)
                },
                longTapStartedAction: {
                    viewModel.handle(viewEvent: .longTapPressed)
                },
                longTapEndedAction: {
                    viewModel.handle(viewEvent: .longTapEnded)
                }
            )
        }
    }

    private func handleShortTap(_ tapLocation: CGPoint, proxy: GeometryProxy) {
        let threshold = Constants.tapToBackThresholdPercentage * proxy.size.width

        let viewEvent: StoryViewEvent = tapLocation.x < threshold
            ? .tappedBackward
            : .tappedForward

        viewModel.handle(viewEvent: viewEvent)
    }
}

// MARK: - Private nested types

extension StoryView {
    fileprivate enum CubicRotation {
        static let perspective: CGFloat = 2.5

        static func angle(_ proxy: GeometryProxy) -> Angle {
            let progress = proxy.frame(in: .global).minX / proxy.size.width
            let squareRotationAngle: Double = 45
            return Angle(degrees: squareRotationAngle * progress)
        }

        static func anchor(_ proxy: GeometryProxy) -> UnitPoint {
            proxy.frame(in: .global).minX > 0
                ? .leading
                : .trailing
        }
    }

    private enum Constants {
        /// 0.25
        static let tapToBackThresholdPercentage: CGFloat = 0.25
        /// 0.2
        static let longPressMinimumDuration: TimeInterval = 0.2
    }
}

// MARK: - View extensions

private extension View {
    func cubicRotationEffect(_ proxy: GeometryProxy) -> some View {
        // [REDACTED_USERNAME], 0.0001 is a 'any small number close to zero'. Used to silence warning that may happen during transition backwards.
        rotation3DEffect(
            StoryView.CubicRotation.angle(proxy),
            axis: (x: 0.0001, y: 1, z: 0),
            anchor: StoryView.CubicRotation.anchor(proxy),
            perspective: StoryView.CubicRotation.perspective
        )
    }
}

extension StoryView {
    private struct GestureRecognizerView: UIViewRepresentable {
        let tapAction: (CGPoint) -> Void
        let longTapStartedAction: () -> Void
        let longTapEndedAction: () -> Void

        func makeUIView(context: Context) -> some UIView {
            let view = GestureRecognizerUIView(
                tapAction: tapAction,
                longTapStartedAction: longTapStartedAction,
                longTapEndedAction: longTapEndedAction
            )
            view.backgroundColor = .clear
            return view
        }

        func updateUIView(_ uiView: UIViewType, context: Context) {}
    }

    private final class GestureRecognizerUIView: UIView {
        let tapAction: (CGPoint) -> Void
        let longTapStartedAction: () -> Void
        let longTapEndedAction: () -> Void

        init(
            tapAction: @escaping (CGPoint) -> Void,
            longTapStartedAction: @escaping () -> Void,
            longTapEndedAction: @escaping () -> Void
        ) {
            self.tapAction = tapAction
            self.longTapStartedAction = longTapStartedAction
            self.longTapEndedAction = longTapEndedAction

            super.init(frame: .zero)

            setupGestures()
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func setupGestures() {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(Self.handleTapGesture))
            addGestureRecognizer(tapGesture)

            let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(Self.handleLongTapGesture))
            longTapGesture.minimumPressDuration = Constants.longPressMinimumDuration
            addGestureRecognizer(longTapGesture)
        }

        @objc
        private func handleTapGesture(_ gesture: UITapGestureRecognizer) {
            let tapLocation = gesture.location(in: gesture.view)
            tapAction(tapLocation)
        }

        @objc
        private func handleLongTapGesture(_ gesture: UILongPressGestureRecognizer) {
            switch gesture.state {
            case .began:
                longTapStartedAction()

            case .ended, .cancelled:
                longTapEndedAction()

            default:
                break
            }
        }
    }
}
