import UIKit
import SwiftUI

/// 키보드 Extension의 메인 컨트롤러
class KeyboardViewController: UIInputViewController {

    // MARK: - Properties

    private var viewModel: KeyboardViewModel!
    private var hostingController: UIHostingController<KeyboardExtensionView>?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        print("⌨️ [Extension] 키보드 로드 시작")

        viewModel = KeyboardViewModel()
        setupKeyboardView()

        print("✅ [Extension] 키보드 초기화 완료")
    }

    // MARK: - Setup

    private func setupKeyboardView() {
        let keyboardView = KeyboardExtensionView(
            viewModel: viewModel,
            onTextCommit: { [weak self] text in
                self?.handleTextCommit(text)
            },
            onComposingChange: { [weak self] text in
                self?.handleComposingChange(text)
            },
            onBackspace: { [weak self] in
                self?.handleBackspace()
            },
            onSpace: { [weak self] in
                self?.handleSpace()
            },
            onReturn: { [weak self] in
                self?.handleReturn()
            },
            onGlobePress: { [weak self] in
                self?.handleGlobePress()
            },
            onGetLastChar: { [weak self] in
                self?.getLastCharacter()
            }
        )

        hostingController = UIHostingController(rootView: keyboardView)

        guard let hostingController = hostingController else {
            print("❌ [Extension] HostingController 생성 실패")
            return
        }

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)

        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        hostingController.view.backgroundColor = .clear
    }

    // MARK: - Text Input Handlers

    /// 텍스트 커밋 (확정)
    private func handleTextCommit(_ text: String) {
        guard !text.isEmpty else { return }

        print("📝 [Extension] 텍스트 커밋: '\(text)'")
        textDocumentProxy.insertText(text)
        logDocumentContext()
    }

    /// 조합 중 텍스트 변경
    private func handleComposingChange(_ text: String) {
        print("🔄 [Extension] 조합 중 텍스트: '\(text)'")

        // markedText 설정 (빈 문자열이어도 setMarkedText로 제거)
        textDocumentProxy.setMarkedText(
            text,
            selectedRange: NSRange(location: text.count, length: 0)
        )
    }

    /// 백스페이스 처리
    private func handleBackspace() {
        print("⌫ [Extension] 백스페이스 실행")
        textDocumentProxy.deleteBackward()
        logDocumentContext()
    }

    /// 스페이스 처리
    private func handleSpace() {
        print("␣ [Extension] 스페이스 입력")
        textDocumentProxy.unmarkText()
        textDocumentProxy.insertText(" ")
    }

    /// 엔터 처리
    private func handleReturn() {
        print("↵ [Extension] 엔터 입력")
        textDocumentProxy.unmarkText()
        textDocumentProxy.insertText("\n")
    }

    /// 키보드 전환
    private func handleGlobePress() {
        print("🌐 [Extension] 키보드 전환")
        advanceToNextInputMode()
    }

    // MARK: - Helper Methods

    private func getLastCharacter() -> String? {
        let beforeInput = textDocumentProxy.documentContextBeforeInput ?? ""
        return beforeInput.last.map { String($0) }
    }

    private func logDocumentContext() {
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        let after = textDocumentProxy.documentContextAfterInput ?? ""
        print("📄 [Extension] 커서 앞: '\(before)'")
        print("📄 [Extension] 커서 뒤: '\(after)'")
    }
}
