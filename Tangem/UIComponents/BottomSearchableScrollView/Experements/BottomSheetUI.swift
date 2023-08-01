//
//  BottomSheetUI.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

let delegate = TransitioningDelegate()

struct BottomSheetViewRepresentable<Content: View>: UIViewControllerRepresentable {
    typealias WrappedController = BottomSheetHostingController<Content>
    private let content: Content

    init(content: Content) {
        self.content = content
    }

    func makeUIViewController(context: Context) -> WrappedController {
        let viewController = WrappedController(rootView: content)
        viewController.modalPresentationStyle = .custom
        viewController.transitioningDelegate = delegate
        return viewController
    }

    func updateUIViewController(_ uiViewController: WrappedController, context: Context) {
        uiViewController.modalPresentationStyle = .custom
        uiViewController.transitioningDelegate = delegate
        print("updateUIViewController with context")
    }
}

class TransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    var startFrame: CGRect {
        let rect = CGRect(x: 150, y: 400, width: 50, height: 50)
        return rect
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return AnimatorPresent(startFrame: startFrame)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return AnimatorDismiss(endFrame: startFrame)
    }
}

class BottomSheetHostingController<Content: View>: UIHostingController<Content> {
    override func viewDidLoad() {
        super.viewDidLoad()
        modalPresentationStyle = .custom
        transitioningDelegate = delegate
        view.backgroundColor = .blue.withAlphaComponent(0.2)
    }
}

class AnimatorPresent: NSObject, UIViewControllerAnimatedTransitioning {
    let startFrame: CGRect

    init(startFrame: CGRect) {
        self.startFrame = startFrame
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 2.0
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        // 1
        guard let fromVC = transitionContext.viewController(forKey: .from),
              let toVC = transitionContext.viewController(forKey: .to),
              let snapshot = toVC.view.snapshotView(afterScreenUpdates: true)
        else {
            return
        }

        // 2
        let containerView = transitionContext.containerView
        let finalFrame = transitionContext.finalFrame(for: toVC)

        // 3
        snapshot.frame = startFrame
        snapshot.layer.cornerRadius = CardViewController.cardCornerRadius
        snapshot.layer.masksToBounds = true

        // 1
        containerView.addSubview(toVC.view)
        containerView.addSubview(snapshot)
        toVC.view.isHidden = true

        // 2
        AnimationHelper.perspectiveTransform(for: containerView)
        snapshot.layer.transform = AnimationHelper.yRotation(.pi / 2)
        // 3
        let duration = transitionDuration(using: transitionContext)

        UIView.animateKeyframes(
            withDuration: duration,
            delay: 0,
            options: .calculationModeCubic,
            animations: {
                // 2
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 1 / 3) {
                    fromVC.view.layer.transform = AnimationHelper.yRotation(-.pi / 2)
                }

                // 3
                UIView.addKeyframe(withRelativeStartTime: 1 / 3, relativeDuration: 1 / 3) {
                    snapshot.layer.transform = AnimationHelper.yRotation(0.0)
                }

                // 4
                UIView.addKeyframe(withRelativeStartTime: 2 / 3, relativeDuration: 1 / 3) {
                    snapshot.frame = finalFrame
                    snapshot.layer.cornerRadius = 0
                }
            },
            // 5
            completion: { _ in
                toVC.view.isHidden = false
                snapshot.removeFromSuperview()
                fromVC.view.layer.transform = CATransform3DIdentity
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        )
    }
}

class AnimatorDismiss: NSObject, UIViewControllerAnimatedTransitioning {
    let endFrame: CGRect

    init(endFrame: CGRect) {
        self.endFrame = endFrame
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let vcTo = transitionContext.viewController(forKey: .to),
              let vcFrom = transitionContext.viewController(forKey: .from),
              let snapshot = vcFrom.view.snapshotView(afterScreenUpdates: true) else {
            return
        }

        let vContainer = transitionContext.containerView
        vContainer.addSubview(vcTo.view)
        vContainer.addSubview(snapshot)

        vcFrom.view.isHidden = true

        UIView.animate(withDuration: 0.3, animations: {
            snapshot.frame = self.endFrame
        }, completion: { success in
            transitionContext.completeTransition(true)
        })
    }
}

struct BottomSheetUI_Previews: PreviewProvider {
    struct StatableContainer: View {
        @ObservedObject private var coordinator = BottomSheetCoordinator()

        var body: some View {
            ZStack {
                Colors.Background.primary
                    .edgesIgnoringSafeArea(.all)

                Button("Bottom sheet isShowing \((coordinator.item != nil).description)") {
                    coordinator.toggleItem()
                }
                .font(Fonts.Bold.body)
                .offset(y: -200)

                NavHolder()
                    .presentScreen(isPresented: $coordinator.isPresented, modalPresentationStyle: .custom, content: {
                        Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit.")
                    })
            }
        }
    }

    struct BottomSheetViewModel: Identifiable {
        var id: String { payload }

        let payload: String = "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
        let close: () -> Void
    }

    struct BottomSheetView: View {
        let viewModel: BottomSheetViewModel

        var body: some View {
            VStack {
                GroupedSection(viewModel) { viewModel in
                    ForEach(0 ..< 3) { _ in
                        Text(viewModel.payload)
                            .padding(.vertical)

                        Divider()
                    }
                }

                VStack {
                    MainButton(title: Localization.commonCancel, style: .primary, action: viewModel.close)

                    MainButton(title: Localization.commonClose, style: .secondary, action: viewModel.close)
                }
            }
            .padding(.horizontal)
        }
    }

    class BottomSheetCoordinator: ObservableObject {
        @Published var item: BottomSheetViewModel?
        @Published var isPresented: Bool = false

        func toggleItem() {
            isPresented.toggle()
//
//            if item == nil {
//                item = BottomSheetViewModel { [weak self] in
//                    self?.item = nil
//                }
//            } else {
//                item = nil
//            }
        }
    }

    static var previews: some View {
        StatableContainer()
            .preferredColorScheme(.dark)
    }
}

extension View {
    func presentScreen<Content>(
        isPresented: Binding<Bool>,
        modalPresentationStyle: UIModalPresentationStyle,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View where Content: View {
        if isPresented.wrappedValue {
            let viewController = BottomSheetHostingController(rootView: content())
            viewController.modalPresentationStyle = modalPresentationStyle
            viewController.transitioningDelegate = delegate

            UIApplication.topViewController?.present(
                viewController,
                animated: true,
                completion: nil
            )

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPresented.wrappedValue = false
            }
        }

        return self
    }
}
