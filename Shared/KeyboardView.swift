import SwiftUI

// MARK: - 메인 키보드 뷰
struct KeyboardView: View {
    @ObservedObject var viewModel: KeyboardViewModel
    let layout: [[KeyboardKey]]
    
    var body: some View {
        VStack(spacing: 0) {
            // 텍스트 표시 영역
            //TextDisplayView(text: viewModel.displayText)
            
            // 키보드 그리드
            VStack(spacing: 6) {
                ForEach(0..<layout.count, id: \.self) { row in
                    HStack(spacing: 6) {
                        ForEach(layout[row]) { key in
                            KeyButtonView(
                                key: key,
                                onInput: { direction in
                                    viewModel.handleKeyInput(key, direction: direction)
                                }
                            )
                        }
                    }
                }
            }
            .padding()
            .background(Color(UIColor.systemGray5))
        }
    }
}

// MARK: - 텍스트 표시 뷰
struct TextDisplayView: View {
    let text: String
    
    var body: some View {
        HStack {
            Text(text.isEmpty ? "입력 대기 중..." : text)
                .font(.system(size: 24))
                .foregroundColor(text.isEmpty ? .gray : .primary)
                .padding()
            
            Spacer()
        }
        .frame(height: 80)
        .background(Color.white)
    }
}

// MARK: - 키 버튼 뷰
struct KeyButtonView: View {
    let key: KeyboardKey
    let onInput: (SwipeDirection) -> Void
    
    @State private var isPressed = false
    @State private var dragStart: CGPoint = .zero
    @State private var currentDrag: CGPoint = .zero
    
    // 햅틱
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    
    private let swipeThreshold: CGFloat = 20
    
    var body: some View {
        ZStack {
            // 키 배경
            RoundedRectangle(cornerRadius: 8)
                .fill(isPressed ? Color.blue.opacity(0.3) : Color.white)
                .shadow(radius: 1)
            
            // 스와이프 방향 힌트
            if hasSwipeOptions {
                SwipeHintsView(key: key)
            }
            
            // 메인 텍스트
            Text(key.defaultValue)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(isPressed ? .blue : .primary)
        }
        .frame(height: 50)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if !isPressed {
                        isPressed = true
                        dragStart = value.location
                        impactFeedback.impactOccurred()
                    }
                    currentDrag = value.location
                }
                .onEnded { value in
                    let direction = getSwipeDirection(
                        start: dragStart,
                        end: value.location
                    )
                    
                    selectionFeedback.selectionChanged()
                    onInput(direction)
                    
                    isPressed = false
                    dragStart = .zero
                    currentDrag = .zero
                }
        )
    }
    
    private var hasSwipeOptions: Bool {
        key.left != nil || key.right != nil || key.up != nil || key.down != nil
    }
    
    private func getSwipeDirection(start: CGPoint, end: CGPoint) -> SwipeDirection {
        let dx = end.x - start.x
        let dy = end.y - start.y
        
        if abs(dx) < swipeThreshold && abs(dy) < swipeThreshold {
            return .none
        }
        
        if abs(dx) > abs(dy) {
            return dx > 0 ? .right : .left
        } else {
            return dy > 0 ? .down : .up
        }
    }
}

// MARK: - 스와이프 힌트 뷰
struct SwipeHintsView: View {
    let key: KeyboardKey
    
    var body: some View {
        ZStack {
            // 왼쪽
            if let left = key.left {
                Text(left.display)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .offset(x: -25, y: 0)
            }
            
            // 오른쪽
            if let right = key.right {
                Text(right.display)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .offset(x: 25, y: 0)
            }
            
            // 위
            if let up = key.up {
                Text(up.display)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .offset(x: 0, y: -15)
            }
            
            // 아래
            if let down = key.down {
                Text(down.display)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .offset(x: 0, y: 15)
            }
        }
    }
}

// MARK: - Preview
struct KeyboardView_Previews: PreviewProvider {
    static var previews: some View {
        KeyboardView(
            viewModel: KeyboardViewModel(),
            layout: KeyboardLayoutManager.getQWERTYLayout()
        )
    }
}
