import Foundation
import SwiftUI
import Combine

// MARK: - 키보드 ViewModel (v5 엔진 통합 + Extension 지원)
class KeyboardViewModel: ObservableObject {
    @Published var displayText: String = ""
    @Published var composingText: String = ""  // 조합 중인 텍스트
    
    private let engine = HangulInputEngine()
    
    init() {
        print("[ViewModel] v5 엔진 통합 초기화 (Extension 지원)")
    }
    
    // MARK: - 공개 메서드
    
    /// 키 입력 처리
    func handleKeyInput(_ key: KeyboardKey, direction: SwipeDirection) {
        print("\n[ViewModel] 키 입력 - 기본:\(key.defaultValue) 방향:\(direction)")
        
        // 특수 키 처리
        if let specialType = key.specialType {
            handleSpecialKey(specialType)
            return
        }
        
        // 엔진 키와 표시 문자 결정
        let engineKey: String
        let displayChar: String
        
        switch direction {
        case .left:
            engineKey = key.left?.engine ?? key.engineKey
            displayChar = key.left?.display ?? key.defaultValue
        case .right:
            engineKey = key.right?.engine ?? key.engineKey
            displayChar = key.right?.display ?? key.defaultValue
        case .up:
            engineKey = key.up?.engine ?? key.engineKey
            displayChar = key.up?.display ?? key.defaultValue
        case .down:
            engineKey = key.down?.engine ?? key.engineKey
            displayChar = key.down?.display ?? key.defaultValue
        case .none:
            engineKey = key.engineKey
            displayChar = key.defaultValue
        }
        
        // 엔진 키가 비어있으면 특수문자로 직접 입력
        if engineKey.isEmpty {
            print("[ViewModel] 특수문자 직접 입력: '\(displayChar)'")
            engine.commitCurrent()  // 현재 조합 커밋
            displayText = engine.displayText + displayChar
            composingText = ""
            return
        }
        
        // 복합 키 처리 (예: "nj" = n + j)
        if engineKey.count > 1 {
            print("[ViewModel] 복합 키 입력: \(engineKey)")
            for char in engineKey {
                engine.processKey(String(char))
            }
        } else {
            engine.processKey(engineKey)
        }
        
        updateDisplay()
    }
    
    /// 특수 키 처리
    private func handleSpecialKey(_ type: SpecialKeyType) {
        switch type {
        case .delete:
            print("[ViewModel] 백스페이스 처리")
            engine.processBackspace()
            updateDisplay()
            
        case .space:
            print("[ViewModel] 스페이스 처리 - 조합 커밋")
            engine.commitCurrent()
            displayText = engine.displayText
            composingText = ""
            
        case .enter:
            print("[ViewModel] 엔터 처리 - 조합 커밋")
            engine.commitCurrent()
            displayText = engine.displayText
            composingText = ""
            
        case .numberToggle, .empty:
            break
        }
    }
    
    /// 화면 업데이트
    private func updateDisplay() {
        let state = engine.getState()
        displayText = state.display
        composingText = state.composing
        
        print("[ViewModel] 화면 업데이트")
        print("  - 전체: '\(displayText)'")
        print("  - 조합중: '\(composingText)'")
    }
    
    /// 리셋
    func reset() {
        engine.reset()
        displayText = ""
        composingText = ""
        print("[ViewModel] 리셋 완료")
    }
    
    /// 현재 상태 가져오기
    func getState() -> (composing: String, committed: String, display: String) {
        return engine.getState()
    }
    
    /// 강제 커밋 (Extension에서 사용)
    func commitCurrent() {
        engine.commitCurrent()
        displayText = engine.displayText
        composingText = ""
        print("[ViewModel] 강제 커밋 완료")
    }
}
