//
//  KYCHeaderView.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemAssets

// [REDACTED_TODO_COMMENT]
// [REDACTED_INFO]
struct KYCHeaderView: View {
    let stepPublisher: AnyPublisher<KYCStep, Never>
    let back: () -> Void
    let close: () -> Void

    @State private var step: KYCStep = .status

    var body: some View {
        VStack(spacing: .zero) {
            HStack {
                Button(
                    shouldHideBackButton ? "Close" : "Back",
                    action: shouldHideBackButton ? close : back
                )

                Spacer()

                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)

                Spacer()

                Button("Close", action: close)
                    .opacity(shouldHideBackButton ? 0 : 1)
            }
            .padding(.horizontal, 16)

            switch step {
            case .status:
                Assets.Onboarding
                    .walletCard
                    .image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: UIScreen.main.bounds.width / 3)
                    .padding(.top, 24)
                    .padding(.bottom, 24)

            case .docTypeSelector:
                Text("Select type and issuing country of your identity document")
                    .font(Fonts.Bold.title1)
                    .foregroundColor(Color(hex: "#1E1E1E"))
                    .multilineTextAlignment(.center)
                    .padding(.top, 40)
                    .padding(.bottom, 28)
                    .padding(.horizontal, 38)

            case .agreementSelector, .questionnaire, .liveness:
                EmptyView()
            }
        }
        .onReceive(stepPublisher) { step in
            self.step = step
        }
    }

    private var title: String {
        switch step {
        case .status:
            "Account verification"
        case .agreementSelector:
            "Country of residence"
        case .questionnaire:
            "Personal information"
        case .docTypeSelector:
            "Upload document"
        case .liveness:
            "Liveness check"
        }
    }

    private var shouldHideBackButton: Bool {
        switch step {
        case .status, .agreementSelector:
            true
        default:
            false
        }
    }
}

class KYCHeaderUIView: UIView {
    // MARK: – Public API

    init(
        stepPublisher: AnyPublisher<KYCStep, Never>,
        back: @escaping () -> Void,
        close: @escaping () -> Void
    ) {
        backAction = back
        closeAction = close
        super.init(frame: .zero)
        setupViews()
        subscribe(to: stepPublisher)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // MARK: – Private

    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private let contentContainer = UIView()

    private var step: KYCStep = .status {
        didSet { updateUI(for: step) }
    }

    private var cancellable: AnyCancellable?
    private let backAction: () -> Void
    private let closeAction: () -> Void

    private func setupViews() {
        // Buttons
        backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        closeButton.setTitle("Close", for: .normal)
        closeButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)

        // Title
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .black

        // Container
        addSubview(backButton)
        addSubview(titleLabel)
        addSubview(closeButton)
        addSubview(contentContainer)

        // Layout
        [backButton, titleLabel, closeButton, contentContainer].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        NSLayoutConstraint.activate([
            // Top row
            backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            backButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            closeButton.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),

            // Content below
            contentContainer.topAnchor.constraint(equalTo: backButton.bottomAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        // Initial state
        updateUI(for: step)
    }

    private func subscribe(to pub: AnyPublisher<KYCStep, Never>) {
        cancellable = pub
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.step = $0 }
    }

    private func updateUI(for step: KYCStep) {
        // 1) Back vs Close on left
        let hideBack = (step == .status || step == .agreementSelector)
        backButton.setTitle(hideBack ? "Close" : "Back", for: .normal)

        // 2) Close button on right hides when left is Close
        closeButton.isHidden = hideBack

        // 3) Title
        titleLabel.text = {
            switch step {
            case .status: return "Account verification"
            case .agreementSelector: return "Country of residence"
            case .questionnaire: return "Personal information"
            case .docTypeSelector: return "Upload document"
            case .liveness: return "Liveness check"
            }
        }()

        // 4) Replace content
        contentContainer.subviews.forEach { $0.removeFromSuperview() }
        switch step {
        case .status:
            let iv = UIImageView(image: Assets.Onboarding.walletCard.uiImage)
            iv.contentMode = .scaleAspectFit
            contentContainer.addSubview(iv)
            iv.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                iv.centerXAnchor.constraint(equalTo: contentContainer.centerXAnchor),
                iv.topAnchor.constraint(equalTo: contentContainer.topAnchor, constant: 24),
                iv.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor, constant: -24),
                iv.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width / 3),
            ])

        case .docTypeSelector:
            let lbl = UILabel()
            lbl.text = "Select type and issuing country of your identity document"
            lbl.font = UIFont.boldSystemFont(ofSize:
                UIFont.preferredFont(forTextStyle: .title1).pointSize
            )
            lbl.textColor = UIColor(hex: "#1E1E1E")
            lbl.numberOfLines = 0
            lbl.textAlignment = .center
            contentContainer.addSubview(lbl)
            lbl.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                lbl.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 38),
                lbl.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -38),
                lbl.topAnchor.constraint(equalTo: contentContainer.topAnchor, constant: 40),
                lbl.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor, constant: -28),
            ])

        default:
            break
        }
    }

    @objc
    private func didTapBack() { backAction() }
    @objc
    private func didTapClose() { closeAction() }
}
