import Foundation

struct Composition {
    var chosung: String = ""
    var jungsung: String = ""
    var jongsung: String = ""
    var isDone: Bool = false
    
    var size: Int {
        chosung.count + jungsung.count + jongsung.count
    }
    
    var isEmpty: Bool {
        size == 0
    }
}

class DubeolKeyboard {
    private let chosungMap: [String: String] = [
        "r": "ㄱ", "R": "ㄲ", "s": "ㄴ", "e": "ㄷ", "E": "ㄸ",
        "f": "ㄹ", "a": "ㅁ", "q": "ㅂ", "Q": "ㅃ", "t": "ㅅ",
        "T": "ㅆ", "d": "ㅇ", "w": "ㅈ", "W": "ㅉ", "c": "ㅊ",
        "z": "ㅋ", "x": "ㅌ", "v": "ㅍ", "g": "ㅎ"
    ]
    
    private let jungsungMap: [String: String] = [
        "k": "ㅏ", "o": "ㅐ", "i": "ㅑ", "O": "ㅒ", "j": "ㅓ",
        "p": "ㅔ", "u": "ㅕ", "P": "ㅖ", "h": "ㅗ", "y": "ㅛ",
        "n": "ㅜ", "b": "ㅠ", "m": "ㅡ", "l": "ㅣ"
    ]
    
    private let jongsungMap: [String: String] = [
        "r": "ㄱ", "R": "ㄲ", "s": "ㄴ", "e": "ㄷ", "f": "ㄹ",
        "a": "ㅁ", "q": "ㅂ", "t": "ㅅ", "T": "ㅆ", "d": "ㅇ",
        "w": "ㅈ", "c": "ㅊ", "z": "ㅋ", "x": "ㅌ", "v": "ㅍ", "g": "ㅎ"
    ]
    
    private let ssangjaeumSet: Set<String> = ["ㄲ", "ㄸ", "ㅃ", "ㅆ", "ㅉ"]
    private let diphthongMap: [String: String] = [
        "ㅗㅏ": "ㅘ", "ㅗㅐ": "ㅙ", "ㅗㅣ": "ㅚ",
        "ㅜㅓ": "ㅝ", "ㅜㅔ": "ㅞ", "ㅜㅣ": "ㅟ", "ㅡㅣ": "ㅢ"
    ]
    private let ggeotbatchimSet: Set<String> = [
        "ㄱㅅ", "ㄴㅈ", "ㄴㅎ", "ㄹㄱ", "ㄹㅁ", "ㄹㅂ",
        "ㄹㅅ", "ㄹㅌ", "ㄹㅍ", "ㄹㅎ", "ㅂㅅ"
    ]
    
    func getChosung(_ key: String) -> String? { chosungMap[key] }
    func getJungsung(_ key: String) -> String? { jungsungMap[key] }
    func getJongsung(_ key: String) -> String? { jongsungMap[key] }
    func isChosung(_ key: String) -> Bool { chosungMap[key] != nil }
    func isJungsung(_ key: String) -> Bool { jungsungMap[key] != nil }
    
    func canCombineSsangjaeum(_ a: String, _ b: String) -> Bool {
        a == b && ssangjaeumSet.contains(a)
    }
    func canCombineDiphthong(_ a: String, _ b: String) -> Bool {
        diphthongMap[a + b] != nil
    }
    func canCombineGgeotbatchim(_ a: String, _ b: String) -> Bool {
        ggeotbatchimSet.contains(a + b)
    }
}

class HangulAutomata {
    private var inputBuffer: [String] = []
    private let keyboard = DubeolKeyboard()
    
    init() {
        print("[v5 오토마타] 초기화\n")
    }
    
    func process(key: String) -> Composition {
        print("[입력] '\(key)'")
        inputBuffer.append(key)
        print("[버퍼] \(inputBuffer)")
        
        let comp = runStateMachine()
        print("[결과] 초:\(comp.chosung) 중:\(comp.jungsung) 종:\(comp.jongsung) 완료:\(comp.isDone)\n")
        
        return comp
    }
    
    func backspace() -> Bool {
        guard !inputBuffer.isEmpty else {
            print("[백스페이스] 버퍼 비어있음\n")
            return false
        }
        
        inputBuffer.removeLast()
        print("[백스페이스] 버퍼: \(inputBuffer)\n")
        return !inputBuffer.isEmpty
    }
    
    func flush() -> Composition {
        let comp = runStateMachine()
        inputBuffer.removeAll()
        return comp
    }
    
    func getCurrentComposition() -> Composition {
        return runStateMachine()
    }
    
    func reset() {
        inputBuffer.removeAll()
    }
    
    private func runStateMachine() -> Composition {
        var comp = Composition()
        
        for (idx, key) in inputBuffer.enumerated() {
            print("  [\(idx)] '\(key)'", terminator: "")
            
            if keyboard.isJungsung(key) {
                guard let jamo = keyboard.getJungsung(key) else { continue }
                print(" → 중성 '\(jamo)'")
                processJungsung(&comp, jamo: jamo)
            } else if keyboard.isChosung(key) {
                if comp.jungsung.isEmpty {
                    guard let jamo = keyboard.getChosung(key) else { continue }
                    print(" → 초성 '\(jamo)'")
                    processChosung(&comp, jamo: jamo)
                } else {
                    guard let jamo = keyboard.getJongsung(key) else { continue }
                    print(" → 종성 '\(jamo)'")
                    processJongsung(&comp, jamo: jamo)
                }
            }
            
            if comp.isDone {
                print("      ✓ 조합 완료!")
                break
            }
        }
        
        if comp.isDone {
            let consumed = comp.size
            for _ in 0..<consumed {
                if !inputBuffer.isEmpty {
                    inputBuffer.removeFirst()
                }
            }
            print("      → \(consumed)개 소비, 남은 버퍼: \(inputBuffer)")
        }
        
        return comp
    }
    
    private func processChosung(_ comp: inout Composition, jamo: String) {
        if comp.chosung.isEmpty {
            print("      [초성] 추가")
            comp.chosung = jamo
        } else {
            if !comp.jungsung.isEmpty {
                print("      [초성] 초+중 상태 → 완료")
                comp.isDone = true
            } else {
                if keyboard.canCombineSsangjaeum(comp.chosung, jamo) {
                    print("      [초성] 쌍자음")
                    comp.chosung = jamo
                } else {
                    print("      [초성] 쌍자음 불가 → 완료")
                    comp.isDone = true
                }
            }
        }
    }
    
    private func processJungsung(_ comp: inout Composition, jamo: String) {
        if comp.jungsung.isEmpty {
            print("      [중성] 추가")
            comp.jungsung = jamo
        } else if !comp.jongsung.isEmpty {
            // ★★★ 핵심: 종성 분리 ★★★
            print("      [중성] 초+중+종 상태 → 종성 분리")

            if comp.jongsung.count == 2 {
                print("      [중성] 겹받침 → 첫 자음만 남김")
                comp.jongsung = String(comp.jongsung.prefix(1))
            } else {
                print("      [중성] 종성 제거!")
                comp.jongsung = ""  // ★ 종성 비움!
            }
            comp.isDone = true
        } else {
            if keyboard.canCombineDiphthong(comp.jungsung, jamo) {
                print("      [중성] 이중모음")
                comp.jungsung = comp.jungsung + jamo
            } else {
                print("      [중성] 이중모음 불가 → 완료")
                comp.isDone = true
            }
        }
    }
    
    private func processJongsung(_ comp: inout Composition, jamo: String) {
        if comp.jongsung.isEmpty {
            print("      [종성] 추가")
            comp.jongsung = jamo
        } else {
            if keyboard.canCombineGgeotbatchim(comp.jongsung, jamo) {
                print("      [종성] 겹받침")
                comp.jongsung = comp.jongsung + jamo
            } else {
                print("      [종성] 겹받침 불가 → 완료")
                comp.isDone = true
            }
        }
    }
}
