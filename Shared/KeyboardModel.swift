import Foundation

// MARK: - 키보드 키 모델
struct KeyboardKey: Identifiable, Equatable {
    let id = UUID()
    let defaultValue: String  // 터치 시 표시될 한글
    let engineKey: String     // 오토마타 엔진에 전달할 영문 키
    
    // 스와이프 방향별 값
    let left: KeyMapping?
    let right: KeyMapping?
    let up: KeyMapping?
    let down: KeyMapping?
    
    // 특수 키 타입
    let specialType: SpecialKeyType?
    
    init(defaultValue: String,
         engineKey: String,
         left: (display: String, engine: String)? = nil,
         right: (display: String, engine: String)? = nil,
         up: (display: String, engine: String)? = nil,
         down: (display: String, engine: String)? = nil,
         specialType: SpecialKeyType? = nil) {
        
        self.defaultValue = defaultValue
        self.engineKey = engineKey
        self.left = left.map { KeyMapping(display: $0.display, engine: $0.engine) }
        self.right = right.map { KeyMapping(display: $0.display, engine: $0.engine) }
        self.up = up.map { KeyMapping(display: $0.display, engine: $0.engine) }
        self.down = down.map { KeyMapping(display: $0.display, engine: $0.engine) }
        self.specialType = specialType
    }
    
    static func == (lhs: KeyboardKey, rhs: KeyboardKey) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - 키 매핑 (화면 표시 + 엔진 키)
struct KeyMapping {
    let display: String  // 사용자에게 보여질 한글
    let engine: String   // 엔진에 전달할 영문 키
}

// MARK: - 특수 키 타입
enum SpecialKeyType {
    case delete       // 백스페이스
    case space        // 스페이스
    case enter        // 엔터
    case numberToggle // 숫자 전환
    case empty        // 빈 키
}

// MARK: - 스와이프 방향
enum SwipeDirection {
    case left, right, up, down, none
}

// MARK: - 두벌식 QWERTY 레이아웃
class KeyboardLayoutManager {
    
    static func getQWERTYLayout() -> [[KeyboardKey]] {
        print("⌨️ QWERTY 한글 레이아웃 로드")
        
        return [
            // Row 1: ㄱ ㄴ ㅢ ⌫
            [
                KeyboardKey(
                    defaultValue: "ㄱ", engineKey: "r",
                    left: ("ㅋ", "z"), right: ("ㅋ", "z"), up: ("ㄲ", "R")
                ),
                KeyboardKey(
                    defaultValue: "ㄴ", engineKey: "s",
                    left: ("ㅌ", "x"), right: ("ㅌ", "x"),
                    up: ("ㄸ", "E"), down: ("ㄷ", "e")
                ),
                KeyboardKey(
                    defaultValue: "ㅢ", engineKey: "m",
                    left: ("ㅝ", "nj"), right: ("ㅘ", "hk"),
                    up: ("ㅚ", "hl"), down: ("ㅟ", "nl")
                ),
                KeyboardKey(
                    defaultValue: "⌫", engineKey: "",
                    specialType: .delete
                )
            ],
            
            // Row 2: ㄹ ㅁ ㅣ ?
            [
                KeyboardKey(
                    defaultValue: "ㄹ", engineKey: "f"
                ),
                KeyboardKey(
                    defaultValue: "ㅁ", engineKey: "a",
                    left: ("ㅍ", "v"), right: ("ㅍ", "v"),
                    up: ("ㅃ", "Q"), down: ("ㅂ", "q")
                ),
                KeyboardKey(
                    defaultValue: "ㅣ", engineKey: "l",
                    left: ("ㅓ", "j"), right: ("ㅏ", "k"),
                    up: ("ㅗ", "h"), down: ("ㅜ", "n")
                ),
                KeyboardKey(
                    defaultValue: "?", engineKey: "",  // 특수문자: 직접 입력
                    left: ("!", ""), right: ("~", ""),
                    up: ("@", ""), down: ("#", "")
                )
            ],
            
            // Row 3: ㅅ ㅇ ㅡ ?123
            [
                KeyboardKey(
                    defaultValue: "ㅅ", engineKey: "t",
                    up: ("ㅆ", "T")
                ),
                KeyboardKey(
                    defaultValue: "ㅇ", engineKey: "d"
                ),
                KeyboardKey(
                    defaultValue: "ㅡ", engineKey: "m",
                    left: ("ㅔ", "p"), right: ("ㅐ", "o"),
                    up: ("ㅛ", "y"), down: ("ㅠ", "b")
                ),
                KeyboardKey(
                    defaultValue: "?123", engineKey: "",
                    specialType: .numberToggle
                )
            ],
            
            // Row 4: ㅈ ㅎ .. .
            [
                KeyboardKey(
                    defaultValue: "ㅈ", engineKey: "w",
                    left: ("ㅊ", "c"), right: ("ㅊ", "c"), up: ("ㅉ", "W")
                ),
                KeyboardKey(
                    defaultValue: "ㅎ", engineKey: "g",
                    up: ("ㅎ", "g")
                ),
                KeyboardKey(
                    defaultValue: "..", engineKey: "",
                    left: ("ㅕ", "u"), right: ("ㅑ", "i"),
                    up: ("ㅛ", "y"), down: ("ㅠ", "b")
                ),
                KeyboardKey(
                    defaultValue: ".", engineKey: "",  // 특수문자: 직접 입력
                    left: (",", ""), right: (";", ""),
                    up: (":", ""), down: ("'", "")
                )
            ],
            
            // Row 5: [empty] Space @ ↵
            [
                KeyboardKey(
                    defaultValue: "", engineKey: "",
                    specialType: .empty
                ),
                KeyboardKey(
                    defaultValue: "␣", engineKey: "",
                    specialType: .space
                ),
                KeyboardKey(
                    defaultValue: "@", engineKey: "",  // 특수문자: 직접 입력
                    left: ("#", ""), right: ("_", ""),
                    up: ("/", ""), down: ("-", "")
                ),
                KeyboardKey(
                    defaultValue: "↵", engineKey: "",
                    specialType: .enter
                )
            ]
        ]
    }
}
