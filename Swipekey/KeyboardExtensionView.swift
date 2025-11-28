import SwiftUI

/// Extension용 키보드 메인 뷰
struct KeyboardExtensionView: View {
    @ObservedObject var viewModel: KeyboardViewModel

    // Callbacks - textDocumentProxy 연결
    let onTextCommit: (String) -> Void          // 확정된 텍스트 전송
    let onComposingChange: (String) -> Void     // 조합 중 텍스트 변경
    let onBackspace: () -> Void
    let onSpace: () -> Void
    let onReturn: () -> Void
    let onGlobePress: () -> Void

    private let layout = KeyboardLayoutManager.getQWERTYLayout()

    // 이전 상태 추적
    @State private var lastCommittedText: String = ""
    @State private var lastComposingText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // 조합 중인 텍스트 표시 (키보드 UI에만 - 선택적)
//            if !viewModel.composingText.isEmpty {
//                ComposingTextView(text: viewModel.composingText)
//            }

            // 키보드 그리드
            VStack(spacing: 6) {
                ForEach(0..<layout.count, id: \.self) { row in
                    HStack(spacing: 6) {
                        ForEach(layout[row]) { key in
                            makeKeyButton(for: key)
                        }
                    }
                }
            }
            .padding(8)
            .background(Color(UIColor.systemGray5))
        }
        .frame(height: 280)
        .background(Color(UIColor.systemGray6))
        .onChange(of: viewModel.composingText) { newComposing in
            // ⚠️ 백스페이스 시에는 onChange에서 처리하지 않음!
            // handleKeyInput과 handleBackspacePress에서 명시적으로 처리
            handleComposingChangeFromNormalInput(newComposing)
        }
    }

    // MARK: - Key Button Factory

    @ViewBuilder
    private func makeKeyButton(for key: KeyboardKey) -> some View {
        if let specialType = key.specialType {
            makeSpecialKeyButton(key, type: specialType)
        } else {
            makeNormalKeyButton(key)
        }
    }

    /// 일반 키 버튼
    private func makeNormalKeyButton(_ key: KeyboardKey) -> some View {
        KeyButtonView(
            key: key,
            onInput: { direction in
                handleKeyInput(key, direction: direction)
            }
        )
    }

    /// 특수 키 버튼
    private func makeSpecialKeyButton(_ key: KeyboardKey, type: SpecialKeyType) -> some View {
        Group {
            switch type {
            case .delete:
                DeleteKeyButton(onPress: handleBackspacePress)
            case .space:
                SpaceKeyButton(onPress: handleSpacePress)
            case .enter:
                EnterKeyButton(onPress: handleReturnPress)
            case .numberToggle:
                ToggleKeyButton(label: "?123", onPress: { })
            case .empty:
                EmptyKeyButton()
            }
        }
    }

    // MARK: - Input Handlers

    /// 일반 키 입력 처리
    private func handleKeyInput(_ key: KeyboardKey, direction: SwipeDirection) {
        print("\n[ExtensionView] 키 입력: \(key.defaultValue) 방향:\(direction)")

        // 입력 전 상태
        let beforeState = viewModel.getState()
        print("[ExtensionView] 입력 전 - committed:'\(beforeState.committed)' composing:'\(beforeState.composing)'")

        // ViewModel에 전달
        viewModel.handleKeyInput(key, direction: direction)

        // 입력 후 상태
        let afterState = viewModel.getState()
        print("[ExtensionView] 입력 후 - committed:'\(afterState.committed)' composing:'\(afterState.composing)'")

        // committed 텍스트가 증가했으면 전송
        if afterState.committed != beforeState.committed {
            let newCommitted = String(afterState.committed.dropFirst(beforeState.committed.count))
            if !newCommitted.isEmpty {
                print("[ExtensionView] ✅ 커밋된 텍스트 전송: '\(newCommitted)'")
                onTextCommit(newCommitted)
                lastCommittedText = afterState.committed
            }
        }

        // composing 텍스트 업데이트
        updateComposingText(afterState.composing)
    }

    /// 일반 입력으로 인한 composingText 변경 (onChange에서 호출)
    private func handleComposingChangeFromNormalInput(_ newComposing: String) {
        // onChange는 모든 경우에 발생하므로
        // 백스페이스는 별도 처리되므로 여기서는 스킵
        // (백스페이스는 handleBackspacePress에서 명시적으로 처리)
    }

    /// 조합 중 텍스트 업데이트 (명시적 호출)
    private func updateComposingText(_ newComposing: String) {
        guard newComposing != lastComposingText else { return }

        print("[ExtensionView] 🔄 조합 중 텍스트 변경: '\(lastComposingText)' → '\(newComposing)'")

        // 조합 중 텍스트를 외부 앱에 임시로 표시
        onComposingChange(newComposing)
        lastComposingText = newComposing
    }

    /// 백스페이스 처리
    private func handleBackspacePress() {
        print("[ExtensionView] 백스페이스 터치")

        // 입력 전 상태
        let beforeState = viewModel.getState()
        print("[ExtensionView] 백스페이스 전 - committed:'\(beforeState.committed)' composing:'\(beforeState.composing)'")

        // ViewModel 상태 업데이트
        viewModel.handleKeyInput(
            KeyboardKey(defaultValue: "⌫", engineKey: "", specialType: .delete),
            direction: .none
        )

        // 입력 후 상태
        let afterState = viewModel.getState()
        print("[ExtensionView] 백스페이스 후 - committed:'\(afterState.committed)' composing:'\(afterState.composing)'")

        // ⚠️ 중요: committed가 실제로 줄어들었을 때만 deleteBackward()
        let committedChanged = afterState.committed.count < beforeState.committed.count

        if committedChanged {
            // committed가 줄어들었으면 외부 앱에서도 삭제
            print("[ExtensionView] ✅ committed 감소 → 외부 앱 백스페이스 실행")
            // 1. deleteBackward() 먼저
            onBackspace()
            // 2. composing 업데이트 나중에
            updateComposingText(afterState.composing)
        } else if !beforeState.composing.isEmpty {
            // composing만 변경 → markedText만 업데이트
            print("[ExtensionView] ⏭️ composing만 변경 → markedText 업데이트만")
            updateComposingText(afterState.composing)
        } else if beforeState.composing.isEmpty && afterState.composing.isEmpty {
            // 엔진 히스토리 비어있음 → 외부 텍스트 삭제
            print("[ExtensionView] ✅ 엔진 비어있음 → 외부 앱 백스페이스 실행")
            onBackspace()
        }

        lastCommittedText = afterState.committed
    }

    /// 스페이스 처리
    private func handleSpacePress() {
        print("[ExtensionView] 스페이스 터치")

        let beforeState = viewModel.getState()

        // ViewModel에서 현재 조합 커밋
        viewModel.handleKeyInput(
            KeyboardKey(defaultValue: "␣", engineKey: "", specialType: .space),
            direction: .none
        )

        let afterState = viewModel.getState()

        // 커밋된 텍스트 전송
        if afterState.committed != beforeState.committed {
            let newCommitted = String(afterState.committed.dropFirst(beforeState.committed.count))
            if !newCommitted.isEmpty {
                print("[ExtensionView] ✅ 커밋된 텍스트 전송: '\(newCommitted)'")
                onTextCommit(newCommitted)
                lastCommittedText = afterState.committed
            }
        }

        // 스페이스 전송
        onSpace()

        // composing 텍스트 업데이트 (비어있을 것)
        updateComposingText(afterState.composing)
    }

    /// 엔터 처리
    private func handleReturnPress() {
        print("[ExtensionView] 엔터 터치")

        let beforeState = viewModel.getState()

        // ViewModel에서 현재 조합 커밋
        viewModel.handleKeyInput(
            KeyboardKey(defaultValue: "↵", engineKey: "", specialType: .enter),
            direction: .none
        )

        let afterState = viewModel.getState()

        // 커밋된 텍스트 전송
        if afterState.committed != beforeState.committed {
            let newCommitted = String(afterState.committed.dropFirst(beforeState.committed.count))
            if !newCommitted.isEmpty {
                print("[ExtensionView] ✅ 커밋된 텍스트 전송: '\(newCommitted)'")
                onTextCommit(newCommitted)
                lastCommittedText = afterState.committed
            }
        }

        // 엔터 전송
        onReturn()

        // composing 텍스트 업데이트 (비어있을 것)
        updateComposingText(afterState.composing)
    }
}

// MARK: - Composing Text View

struct ComposingTextView: View {
    let text: String

    var body: some View {
        HStack {
            Text(text)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.95))
                        .shadow(radius: 2)
                )

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Special Key Buttons

struct DeleteKeyButton: View {
    let onPress: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: onPress) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isPressed ? Color.gray.opacity(0.5) : Color.gray.opacity(0.3))

                Image(systemName: "delete.left")
                    .font(.system(size: 24))
                    .foregroundColor(.black)
            }
        }
        .frame(height: 50)
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

struct SpaceKeyButton: View {
    let onPress: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: onPress) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isPressed ? Color.white.opacity(0.7) : Color.white)

                Text("space")
                    .font(.system(size: 16))
                    .foregroundColor(.black)
            }
        }
        .frame(height: 50)
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

struct EnterKeyButton: View {
    let onPress: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: onPress) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isPressed ? Color.blue.opacity(0.7) : Color.blue)

                Image(systemName: "return")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
        }
        .frame(height: 50)
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

struct ToggleKeyButton: View {
    let label: String
    let onPress: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: onPress) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isPressed ? Color.gray.opacity(0.5) : Color.gray.opacity(0.3))

                Text(label)
                    .font(.system(size: 16))
                    .foregroundColor(.black)
            }
        }
        .frame(height: 50)
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

struct EmptyKeyButton: View {
    var body: some View {
        Color.clear
            .frame(height: 50)
    }
}

// MARK: - Preview

struct KeyboardExtensionView_Previews: PreviewProvider {
    static var previews: some View {
        KeyboardExtensionView(
            viewModel: KeyboardViewModel(),
            onTextCommit: { print("Commit: \($0)") },
            onComposingChange: { print("Composing: \($0)") },
            onBackspace: { print("Backspace") },
            onSpace: { print("Space") },
            onReturn: { print("Return") },
            onGlobePress: { print("Globe") }
        )
        .previewLayout(.fixed(width: 400, height: 280))
    }
}
