import Foundation

// MARK: - 한글 유니코드 변환 유틸리티
struct HangulUnicodeConverter {
    
    // 초성 19자
    private static let chosungList = [
        "ㄱ", "ㄲ", "ㄴ", "ㄷ", "ㄸ", "ㄹ", "ㅁ", "ㅂ", "ㅃ", 
        "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅉ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"
    ]
    
    // 중성 21자
    private static let jungsungList = [
        "ㅏ", "ㅐ", "ㅑ", "ㅒ", "ㅓ", "ㅔ", "ㅕ", "ㅖ", "ㅗ", "ㅘ",
        "ㅙ", "ㅚ", "ㅛ", "ㅜ", "ㅝ", "ㅞ", "ㅟ", "ㅠ", "ㅡ", "ㅢ", "ㅣ"
    ]
    
    // 종성 28자 (없음 포함)
    private static let jongsungList = [
        "", "ㄱ", "ㄲ", "ㄳ", "ㄴ", "ㄵ", "ㄶ", "ㄷ", "ㄹ", "ㄺ", "ㄻ",
        "ㄼ", "ㄽ", "ㄾ", "ㄿ", "ㅀ", "ㅁ", "ㅂ", "ㅄ", "ㅅ", "ㅆ", "ㅇ",
        "ㅈ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"
    ]
    
    // 이중모음 조합 매핑
    private static let diphthongMap: [String: String] = [
        "ㅗㅏ": "ㅘ", "ㅗㅐ": "ㅙ", "ㅗㅣ": "ㅚ",
        "ㅜㅓ": "ㅝ", "ㅜㅔ": "ㅞ", "ㅜㅣ": "ㅟ",
        "ㅡㅣ": "ㅢ"
    ]
    
    // 겹받침 조합 매핑
    private static let ggeotbatchimMap: [String: String] = [
        "ㄱㅅ": "ㄳ", "ㄴㅈ": "ㄵ", "ㄴㅎ": "ㄶ",
        "ㄹㄱ": "ㄺ", "ㄹㅁ": "ㄻ", "ㄹㅂ": "ㄼ",
        "ㄹㅅ": "ㄽ", "ㄹㅌ": "ㄾ", "ㄹㅍ": "ㄿ",
        "ㄹㅎ": "ㅀ", "ㅂㅅ": "ㅄ"
    ]
    
    /// Composition을 완성형 한글로 변환
    static func compose(_ comp: Composition) -> String {
        print("[변환] 조합 시작 - 초성:\(comp.chosung) 중성:\(comp.jungsung) 종성:\(comp.jongsung)")
        
        // 중성이 없으면 자모만 반환
        guard !comp.jungsung.isEmpty else {
            print("[변환] 중성 없음 - 자모 그대로 반환")
            return comp.chosung + comp.jungsung + comp.jongsung
        }
        
        // 중성 조합 (이중모음 처리)
        let finalJungsung = processJungsung(comp.jungsung)
        
        // 종성 조합 (겹받침 처리)
        let finalJongsung = processJongsung(comp.jongsung)
        
        // 초성이 없으면 완성형 불가
        guard !comp.chosung.isEmpty else {
            print("[변환] 초성 없음 - 자모 조합 반환")
            return comp.chosung + finalJungsung + finalJongsung
        }
        
        // 초성, 중성, 종성 인덱스 찾기
        guard let chosungIdx = chosungList.firstIndex(of: comp.chosung),
              let jungsungIdx = jungsungList.firstIndex(of: finalJungsung) else {
            print("[변환] 인덱스 찾기 실패 - 자모 조합 반환")
            return comp.chosung + finalJungsung + finalJongsung
        }
        
        let jongsungIdx = jongsungList.firstIndex(of: finalJongsung) ?? 0
        
        // 완성형 한글 유니코드 계산
        // 유니코드 = ((초성 * 588) + (중성 * 28) + 종성) + 0xAC00
        let unicode = (chosungIdx * 588) + (jungsungIdx * 28) + jongsungIdx + 0xAC00
        
        if let scalar = UnicodeScalar(unicode) {
            let result = String(scalar)
            print("[변환] 완성형 생성 성공: '\(result)' (U+\(String(format: "%04X", unicode)))")
            return result
        } else {
            print("[변환] 유니코드 스칼라 생성 실패 - 자모 조합 반환")
            return comp.chosung + finalJungsung + finalJongsung
        }
    }
    
    /// 중성 처리 (이중모음 조합)
    private static func processJungsung(_ jungsung: String) -> String {
        if jungsung.count > 1, let combined = diphthongMap[jungsung] {
            print("[변환] 이중모음 변환: \(jungsung) -> \(combined)")
            return combined
        }
        return jungsung
    }
    
    /// 종성 처리 (겹받침 조합)
    private static func processJongsung(_ jongsung: String) -> String {
        if jongsung.count > 1, let combined = ggeotbatchimMap[jongsung] {
            print("[변환] 겹받침 변환: \(jongsung) -> \(combined)")
            return combined
        }
        return jongsung
    }
    
    /// 한글 분해 (완성형 -> 초중종)
    static func decompose(_ hangul: String) -> Composition? {
        guard let scalar = hangul.unicodeScalars.first,
              (0xAC00...0xD7A3).contains(scalar.value) else {
            return nil
        }
        
        let code = Int(scalar.value) - 0xAC00
        let chosungIdx = code / 588
        let jungsungIdx = (code % 588) / 28
        let jongsungIdx = code % 28
        
        return Composition(
            chosung: chosungList[chosungIdx],
            jungsung: jungsungList[jungsungIdx],
            jongsung: jongsungList[jongsungIdx],
            isDone: false
        )
    }
}
