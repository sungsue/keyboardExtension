import SwiftUI
import Combine

/// Extension용 키보드 메인 뷰
struct KeyboardExtensionView: View {
    @ObservedObject var viewModel: KeyboardViewModel

    // Callbacks - textDocumentProxy 연결
    let onTextCommit: (String) -> Void
    let onComposingChange: (String) -> Void
    let onBackspace: () -> Void
    let onSpace: () -> Void
    let onReturn: () -> Void
    let onGlobePress: () -> Void
    let onGetLastChar: () -> String?

    private let layout = KeyboardLayoutManager.getQWERTYLayout()

    var body: some View {
        VStack(spacing: 0) {
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
        .frame(height: 340)
        .background(Color(UIColor.systemGray6))
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

    private func makeNormalKeyButton(_ key: KeyboardKey) -> some View {
        KeyButtonView(
            key: key,
            onInput: { direction in
                handleKeyInput(key, direction: direction)
            }
        )
    }

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

        let beforeState = viewModel.getState()
        viewModel.handleKeyInput(key, direction: direction)
        let afterState = viewModel.getState()

        let committedChanged = afterState.committed.count > beforeState.committed.count
        let composingChanged = afterState.composing != beforeState.composing

        // committed 증가 확인
        if committedChanged {
            let newText = String(afterState.committed.dropFirst(beforeState.committed.count))
            print("[ExtensionView] ✅ committed 증가: '\(newText)'")
            onTextCommit(newText)
        }

        // composing 변경 또는 committed 증가 시 composing이 있으면 markedText 재설정
        if composingChanged || (committedChanged && !afterState.composing.isEmpty) {
            print("[ExtensionView] 🔄 composing 업데이트: '\(afterState.composing)'")
            onComposingChange(afterState.composing)
        }
    }

    /// 백스페이스 처리
    private func handleBackspacePress() {
        print("\n[ExtensionView] 백스페이스 터치")

        let beforeState = viewModel.getState()
        print("[ExtensionView] 백스페이스 전 - committed:'\(beforeState.committed)' composing:'\(beforeState.composing)'")

        // 엔진이 비어있는 경우 외부 텍스트 삭제
        if beforeState.committed.isEmpty && beforeState.composing.isEmpty {
            print("[ExtensionView] 엔진 비어있음 → 외부 deleteBackward")
            onBackspace()
            return
        }

        // 엔진의 백스페이스 처리
        viewModel.handleKeyInput(
            KeyboardKey(defaultValue: "⌫", engineKey: "", specialType: .delete),
            direction: .none
        )

        let afterState = viewModel.getState()
        print("[ExtensionView] 백스페이스 후 - committed:'\(afterState.committed)' composing:'\(afterState.composing)' 삭제된키:'\(afterState.deletedKey ?? "nil")'")


        let committedDecreased = afterState.committed.count < beforeState.committed.count
        let hadComposing = !beforeState.composing.isEmpty
        let hasComposing = !afterState.composing.isEmpty

        if committedDecreased {
            // committed가 줄어들었을 때
            let deletedCount = beforeState.committed.count - afterState.committed.count
            print("[ExtensionView] ✅ committed \(deletedCount)글자 감소")

            if hadComposing {
                // markedText가 있었으면 먼저 삭제
                print("[ExtensionView] → markedText 삭제")
                onBackspace()
            }

            // committed 감소한 만큼 삭제
            for i in 0..<deletedCount {
                print("[ExtensionView] → committed 삭제 \(i+1)/\(deletedCount)")
                onBackspace()
            }

            // 새 composing 표시
            if hasComposing {
                print("[ExtensionView] → 새 markedText: '\(afterState.composing)'")
                onComposingChange(afterState.composing)
            }
        } else if hadComposing {
            // composing만 변경 → markedText만 업데이트
            print("[ExtensionView] ⏭️ composing만 변경")
            if afterState.composing != beforeState.composing {
                onComposingChange(afterState.composing)
            }
        }
    }

    /// 스페이스 처리
    private func handleSpacePress() {
        print("\n[ExtensionView] 스페이스 터치")

        let beforeState = viewModel.getState()

        // composing이 있으면 먼저 커밋
        if !beforeState.composing.isEmpty {
            print("[ExtensionView] → composing 커밋: '\(beforeState.composing)'")
            onTextCommit(beforeState.composing)
            onComposingChange("")  // markedText 제거
        }

        // 엔진에 space 처리 (히스토리에 기록)
        viewModel.handleKeyInput(
            KeyboardKey(defaultValue: "␣", engineKey: "", specialType: .space),
            direction: .none
        )

        // 실제 스페이스 입력
        onSpace()
    }

    /// 엔터 처리
    private func handleReturnPress() {
        print("\n[ExtensionView] 엔터 터치")

        let beforeState = viewModel.getState()

        // composing이 있으면 먼저 커밋
        if !beforeState.composing.isEmpty {
            print("[ExtensionView] → composing 커밋: '\(beforeState.composing)'")
            onTextCommit(beforeState.composing)
            onComposingChange("")  // markedText 제거
        }

        // 엔진에 enter 처리 (히스토리에 기록)
        viewModel.handleKeyInput(
            KeyboardKey(defaultValue: "↵", engineKey: "", specialType: .enter),
            direction: .none
        )

        // 실제 엔터 입력
        onReturn()
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
            onGlobePress: { print("Globe") },
            onGetLastChar: { return nil }
        )
        .previewLayout(.fixed(width: 400, height: 280))
    }
}
