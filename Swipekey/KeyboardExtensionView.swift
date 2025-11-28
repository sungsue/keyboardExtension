import SwiftUI

/// Extension용 키보드 메인 뷰
struct KeyboardExtensionView: View {
    @ObservedObject var viewModel: KeyboardViewModel
    
    // Callbacks - textDocumentProxy 연결
    let onTextChange: (String) -> Void
    let onBackspace: () -> Void
    let onSpace: () -> Void
    let onReturn: () -> Void
    let onGlobePress: () -> Void
    
    private let layout = KeyboardLayoutManager.getQWERTYLayout()
    
    // 이전 텍스트 추적 (변경 감지용)
    @State private var previousDisplayText: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // 조합 중인 텍스트 표시
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
        .onChange(of: viewModel.displayText) { newValue in
            handleDisplayTextChange(newValue)
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
    
    /// 특수 키 버튼 (커스텀 처리)
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
        
        // ViewModel에 전달
        viewModel.handleKeyInput(key, direction: direction)
    }
    
    /// 백스페이스 처리
    private func handleBackspacePress() {
        print("[ExtensionView] 백스페이스 터치")
        
        // 1. ViewModel 상태 업데이트
        viewModel.handleKeyInput(
            KeyboardKey(defaultValue: "⌫", engineKey: "", specialType: .delete),
            direction: .none
        )
        
        // 2. 외부 앱 텍스트 삭제
        onBackspace()
    }
    
    /// 스페이스 처리
    private func handleSpacePress() {
        print("[ExtensionView] 스페이스 터치")
        
        // 1. ViewModel에서 현재 조합 커밋
        viewModel.handleKeyInput(
            KeyboardKey(defaultValue: "␣", engineKey: "", specialType: .space),
            direction: .none
        )
        
        // 2. 외부 앱에 스페이스 전송
        onSpace()
    }
    
    /// 엔터 처리
    private func handleReturnPress() {
        print("[ExtensionView] 엔터 터치")
        
        // 1. ViewModel에서 현재 조합 커밋
        viewModel.handleKeyInput(
            KeyboardKey(defaultValue: "↵", engineKey: "", specialType: .enter),
            direction: .none
        )
        
        // 2. 외부 앱에 엔터 전송
        onReturn()
    }
    
    // MARK: - Text Change Handler
    
    /// displayText 변경 감지 및 전송
    private func handleDisplayTextChange(_ newText: String) {
        // 변경된 부분만 추출
        if newText.hasPrefix(previousDisplayText) {
            // 텍스트 추가됨
            let addedText = String(newText.dropFirst(previousDisplayText.count))
            if !addedText.isEmpty {
                print("[ExtensionView] 텍스트 추가: '\(addedText)'")
                onTextChange(addedText)
            }
        } else if previousDisplayText.hasPrefix(newText) {
            // 텍스트 삭제됨 (백스페이스는 별도 처리하므로 무시)
            print("[ExtensionView] 텍스트 삭제 감지 (백스페이스로 처리됨)")
        } else {
            // 완전히 다른 텍스트 (리셋 등)
            print("[ExtensionView] 텍스트 완전 변경")
            if !newText.isEmpty {
                onTextChange(newText)
            }
        }
        
        previousDisplayText = newText
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

/// 백스페이스 키
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

/// 스페이스 키
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

/// 엔터 키
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

/// 숫자/기호 전환 키
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

/// 빈 키
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
            onTextChange: { print("Text: \($0)") },
            onBackspace: { print("Backspace") },
            onSpace: { print("Space") },
            onReturn: { print("Return") },
            onGlobePress: { print("Globe") }
        )
        .previewLayout(.fixed(width: 400, height: 280))
    }
}
