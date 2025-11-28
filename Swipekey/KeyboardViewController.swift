import UIKit
import SwiftUI

/// 키보드 Extension의 메인 컨트롤러
/// UIInputViewController를 상속받아 iOS 키보드 시스템과 통신
class KeyboardViewController: UIInputViewController {

    // MARK: - Properties

    private var viewModel: KeyboardViewModel!
    private var hostingController: UIHostingController<KeyboardExtensionView>?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        print("⌨️ [Extension] 키보드 로드 시작")
        print("📱 [Extension] textDocumentProxy 사용 가능: \(textDocumentProxy)")

        // ViewModel 초기화
        viewModel = KeyboardViewModel()

        // SwiftUI 키보드 뷰 설정
        setupKeyboardView()

        print("✅ [Extension] 키보드 초기화 완료")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("👁️ [Extension] 키보드 나타남")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("👋 [Extension] 키보드 사라짐")
    }

    // MARK: - Setup

    private func setupKeyboardView() {
        // SwiftUI 뷰 생성 - callbacks로 textDocumentProxy 연결
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
            }
        )

        // UIHostingController로 SwiftUI 통합
        hostingController = UIHostingController(rootView: keyboardView)

        guard let hostingController = hostingController else {
            print("❌ [Extension] HostingController 생성 실패")
            return
        }

        // 자식 뷰 컨트롤러로 추가
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)

        // Auto Layout 설정
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // 투명 배경
        hostingController.view.backgroundColor = .clear

        print("✅ [Extension] SwiftUI 키보드 뷰 설정 완료")
    }

    // MARK: - Text Input Handlers

    /// 텍스트 커밋 (확정)
    private func handleTextCommit(_ text: String) {
        guard !text.isEmpty else { return }

        print("📝 [Extension] 텍스트 커밋: '\(text)'")

        // 조합 중 텍스트 제거
        textDocumentProxy.unmarkText()

        // 확정된 텍스트 삽입
        textDocumentProxy.insertText(text)

        logDocumentContext()
    }

    /// 조합 중 텍스트 변경 (임시 표시)
    private func handleComposingChange(_ text: String) {
        print("🔄 [Extension] 조합 중 텍스트: '\(text)'")

        if text.isEmpty {
            // 조합 중 텍스트 제거
            textDocumentProxy.unmarkText()
        } else {
            // 조합 중 텍스트를 외부 앱에 임시로 표시
            textDocumentProxy.setMarkedText(text, selectedRange: NSRange(location: text.count, length: 0))
        }
    }

    /// 백스페이스 처리
    private func handleBackspace() {
        print("⌫ [Extension] 백스페이스 실행")

        // textDocumentProxy로 외부 앱 텍스트 삭제
        textDocumentProxy.deleteBackward()

        logDocumentContext()
    }

    /// 스페이스 처리
    private func handleSpace() {
        print("␣ [Extension] 스페이스 입력")

        // 조합 중 텍스트 제거 (커밋은 Extension에서 처리됨)
        textDocumentProxy.unmarkText()

        textDocumentProxy.insertText(" ")
    }

    /// 엔터 처리
    private func handleReturn() {
        print("↵ [Extension] 엔터 입력")

        // 조합 중 텍스트 제거 (커밋은 Extension에서 처리됨)
        textDocumentProxy.unmarkText()

        textDocumentProxy.insertText("\n")
    }

    /// 키보드 전환 처리
    private func handleGlobePress() {
        print("🌐 [Extension] 키보드 전환")
        advanceToNextInputMode()
    }

    // MARK: - UIInputViewController Overrides

    override func textWillChange(_ textInput: UITextInput?) {
        super.textWillChange(textInput)
        print("📄 [Extension] textWillChange 호출")
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        print("📄 [Extension] textDidChange 호출")
        logDocumentContext()
    }

    // MARK: - Helper Methods

    /// 현재 문서 컨텍스트 로깅
    private func logDocumentContext() {
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        let after = textDocumentProxy.documentContextAfterInput ?? ""

        print("📄 [Extension] 커서 앞: '\(before)'")
        print("📄 [Extension] 커서 뒤: '\(after)'")
    }

    // MARK: - Memory Management

    deinit {
        print("🗑️ [Extension] KeyboardViewController 해제")
    }
}
