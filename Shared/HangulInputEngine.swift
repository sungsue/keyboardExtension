import Foundation

// MARK: - 한글 입력 엔진 (UI 독립)
class HangulInputEngine {
    // MARK: - 공개 속성 (읽기 전용)
    private(set) var composingText: String = ""    // 조합 중인 텍스트
    private(set) var committedText: String = ""    // 확정된 텍스트
    private(set) var displayText: String = ""      // 화면 표시 텍스트 (committed + composing)
    
    // MARK: - 내부 상태
    private let automata = HangulAutomata()
    private var currentComposition = Composition()
    private var keyHistory: [String] = []
    
    init() {
        print("[v5 입력 엔진] 초기화")
    }
    
    // MARK: - 공개 API
    
    /// 키 입력 처리
    /// - Parameter key: 입력된 키 (예: "r", "k", "q")
    /// - Returns: 업데이트 성공 여부
    @discardableResult
    func processKey(_ key: String) -> Bool {
        print("\n[입력 엔진] ✅ 키 입력: '\(key)'")

        // 히스토리에 기록
        keyHistory.append(key)
        print("[입력 엔진] 히스토리 추가 후: \(keyHistory)")

        // 오토마타 처리
        let comp = automata.process(key: key)

        if comp.isDone {
            // 조합 완료 - 커밋
            print("[입력 엔진] 조합 완료 → 커밋")
            commitComposition(comp)

            // 남은 입력으로 새 조합 시작
            currentComposition = automata.getCurrentComposition()
            updateComposingText()
        } else {
            // 조합 중
            currentComposition = comp
            updateComposingText()
        }

        updateDisplayText()
        print("[입력 엔진] 처리 후 화면: '\(displayText)'")

        return true
    }
    
    /// 백스페이스 처리
    /// - Returns: (성공 여부, 삭제된 키)
    @discardableResult
    func processBackspace() -> (success: Bool, deletedKey: String?) {
        print("\n[입력 엔진] 백스페이스")
        print("[입력 엔진] 백스페이스 전 히스토리: \(keyHistory)")

        guard !keyHistory.isEmpty else {
            print("[입력 엔진] ❌ 히스토리 비어있음")
            return (false, nil)
        }

        // 히스토리에서 제거하고 삭제된 키 기록
        let deletedKey = keyHistory.removeLast()
        print("[입력 엔진] 삭제된 키: '\(deletedKey)'")
        print("[입력 엔진] 백스페이스 후 히스토리: \(keyHistory)")

        // 전체 재조합
        recomposeAll()

        print("[입력 엔진] 재조합 후 화면: '\(displayText)'")
        return (true, deletedKey)
    }
    
    /// 강제 커밋 및 리셋 (스페이스, 엔터 입력 시)
    func commitAndReset() {
        print("\n[입력 엔진] 강제 커밋 및 리셋")

        let comp = automata.flush()
        commitComposition(comp)

        // 현재 단어 종료 - 엔진 리셋
        automata.reset()
        currentComposition = Composition()
        composingText = ""
        committedText = ""  // committed도 리셋 (현재 단어만 관리)
        keyHistory.removeAll()

        updateDisplayText()
        print("[입력 엔진] 리셋 완료 - 새 단어 시작")
    }

    /// 전체 초기화
    func reset() {
        print("\n[입력 엔진] 전체 리셋")

        automata.reset()
        currentComposition = Composition()
        composingText = ""
        committedText = ""
        displayText = ""
        keyHistory.removeAll()
    }
    
    /// 현재 상태 정보 가져오기
    func getState() -> (composing: String, committed: String, display: String) {
        return (composingText, committedText, displayText)
    }
    
    /// 키 히스토리 가져오기 (디버깅용)
    func getKeyHistory() -> [String] {
        return keyHistory
    }
    
    // MARK: - 내부 메서드
    
    private func commitComposition(_ comp: Composition) {
        guard !comp.isEmpty else {
            print("[입력 엔진] 빈 조합 - 커밋 스킵")
            return
        }
        
        let hangul = HangulUnicodeConverter.compose(comp)
        committedText += hangul
        print("[입력 엔진] 커밋: '\(hangul)' → 전체: '\(committedText)'")
    }
    
    private func updateComposingText() {
        if currentComposition.isEmpty {
            composingText = ""
        } else {
            composingText = HangulUnicodeConverter.compose(currentComposition)
            print("[입력 엔진] 조합 중: '\(composingText)'")
        }
    }
    
    private func updateDisplayText() {
        displayText = committedText + composingText
    }
    
    /// 전체 키 히스토리로부터 재조합 (현재 단어만)
    private func recomposeAll() {
        print("[입력 엔진] 🔄 재조합 시작 - 히스토리: \(keyHistory)")
        automata.reset()
        committedText = ""
        composingText = ""

        for (index, key) in keyHistory.enumerated() {
            let comp = automata.process(key: key)
            if comp.isDone {
                print("[입력 엔진] 재조합[\(index)]: '\(key)' → 완료")
                commitComposition(comp)
            } else {
                print("[입력 엔진] 재조합[\(index)]: '\(key)' → 조합 중")
            }
        }

        // 마지막 조합 중인 것
        currentComposition = automata.getCurrentComposition()
        updateComposingText()
        updateDisplayText()
        print("[입력 엔진] 🔄 재조합 완료 - committed: '\(committedText)' composing: '\(composingText)'")
    }
}

// MARK: - 델리게이트 패턴 (선택적)
protocol HangulInputEngineDelegate: AnyObject {
    func inputEngine(_ engine: HangulInputEngine, didUpdateDisplay text: String)
    func inputEngine(_ engine: HangulInputEngine, didUpdateComposing text: String)
    func inputEngine(_ engine: HangulInputEngine, didCommit text: String)
}

// MARK: - 델리게이트 지원 확장
extension HangulInputEngine {
//    private weak var delegate: HangulInputEngineDelegate?
//    
//    func setDelegate(_ delegate: HangulInputEngineDelegate) {
//        // 델리게이트 패턴이 필요한 경우 사용
//        // self.delegate = delegate
//    }
}
