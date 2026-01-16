# Code4rena Valid Findings Pattern Archive

실제 Code4rena 감사에서 유효하다고 판정된 발견 패턴을 수집합니다.
이 패턴들은 에이전트가 유사한 취약점을 탐지하는 데 참고 자료로 활용됩니다.

**IMPORTANT**: 이 패턴들은 LLM 학습용이 아닌 참조용입니다. 향후 RLVR 확장 시 활용 예정.

---

## Panoptic (2025-12)

Panoptic은 Uniswap V3/V4 기반의 옵션 프로토콜입니다.

### F-61: Phantom Shares Timing Attack (High)

**카테고리**: State Interaction / Timing Attack

```solidity
// 취약점: settleLiquidation 중 phantom shares의 delegation/revocation 타이밍
// 상태 불일치 윈도우에서 shares가 제거되기 전에 delegation 가능

function settleLiquidation(...) {
    // 1. phantom shares 계산
    // 2. 외부 호출 (콜백 가능!)
    // 3. shares 업데이트  ← 콜백 시점에 아직 미업데이트
}

// 공격: 콜백 중 delegation/revocation으로 phantom shares 이중 사용
```

**탐지 포인트**:
- 상태 업데이트 전 외부 호출
- delegation/revocation 메커니즘
- shares/balance 계산과 실제 전송 타이밍 불일치

### F-25: Credit Leg Accumulation Solvency Bypass (High)

**카테고리**: Logic Error / Economic Attack

```solidity
// 취약점: credit leg accumulation으로 solvency check 우회
// 다중 포지션 조합으로 실제보다 높은 credit 표시

// 정상: position A의 credit + position B의 debit = net value
// 공격: credit만 누적되는 시나리오 구성 → solvency 우회
```

**탐지 포인트**:
- 다중 포지션/leg 시스템
- credit/debit 계산 로직
- solvency/collateral check 우회 가능성
- 포지션 조합의 예외 케이스

### F-59: OraclePack Bit Mask Overflow (Medium)

**카테고리**: Logic Error / Input Validation

```solidity
// 취약점: OraclePack의 비트 마스크 연산 오버플로우
// 큰 값 입력 시 비트 연산 결과가 예상과 다름

function packOracle(uint256 value) returns (bytes32) {
    // value가 예상 범위 초과 시 오버플로우
    return bytes32(value << SHIFT);  // SHIFT 후 손실 발생
}
```

**탐지 포인트**:
- 비트 연산 (<<, >>, &, |)
- 패킹/언패킹 로직
- 경계값 테스트 누락
- 오버플로우 체크 없는 shift

---

## Megapot (2025)

### H-01: settleAuction NFT Position Hijack (High)

**카테고리**: State Interaction / Multi-Step Attack

```solidity
// 취약점: settleAuction 호출 시 NFT 포지션 도용
// 다중 단계 공격으로 타인의 NFT 포지션 획득

// 공격 시나리오:
// 1. auction 참여
// 2. settleAuction 호출 전 특정 조건 조작
// 3. 타인의 NFT 포지션이 공격자에게 이전
```

**탐지 포인트**:
- auction/settlement 분리 로직
- NFT 소유권 이전 조건
- 다중 트랜잭션 간 상태 조작

---

## Ekubo (2025)

### H-01: Oracle Token Metadata Corruption (High)

**카테고리**: Logic Error / State Corruption

```solidity
// 취약점: 오라클 업데이트 시 토큰 메타데이터 손상
// 특정 조건에서 metadata가 올바르지 않은 값으로 덮어씌워짐

function updateOracle(address token, uint256 price) {
    // metadata validation 누락
    oracles[token] = OracleData({
        price: price,
        metadata: corrupted_value  // 검증 없이 저장
    });
}
```

**탐지 포인트**:
- metadata 저장/업데이트 로직
- validation 체크 순서
- 상태 덮어쓰기 조건

---

## Common Patterns (공통 패턴)

### 1. 프로토콜 고유 메커니즘 악용

실제 유효한 발견은 대부분 **프로토콜 고유의 메커니즘**을 악용합니다.
일반적인 패턴 매칭보다 프로토콜 이해가 우선입니다.

```markdown
✅ 유효한 발견:
"Panoptic의 phantom shares delegation이 settleLiquidation 중 콜백에서 악용됨"

❌ 일반적인 발견:
"외부 호출 전 상태 업데이트 필요" (CEI 패턴 위반 일반론)
```

### 2. 다중 트랜잭션/함수 호출 조합

단일 함수가 아닌 **여러 함수의 조합**으로 취약점 발생:

```markdown
공격 시나리오 예시:
1. functionA() 호출 → 상태 A 변경
2. functionB() 호출 → 상태 B 변경 (A에 의존)
3. functionC() 호출 → A와 B의 불일치 악용
```

### 3. 상태 불일치 타이밍 공격

외부 호출 중 발생하는 **상태 불일치 윈도우** 악용:

| 시점 | 상태 A | 상태 B | 불일치 |
|------|--------|--------|--------|
| T0 | 100 | 100 | 일치 |
| T1 (업데이트) | 50 | 100 | ⚠️ 불일치 |
| T2 (콜백) | 50 | 100 | ⚠️ 악용 가능 |
| T3 (완료) | 50 | 50 | 일치 |

### 4. 경계 조건 (Edge Cases)

| 경계값 | 예시 | 위험 |
|--------|------|------|
| **0** | 0 amount deposit/withdraw | Division by zero, 무한 shares |
| **1** | First depositor | Share inflation attack |
| **MAX** | type(uint256).max | Overflow, underflow |
| **Boundary** | 정확히 threshold 값 | Off-by-one errors |

---

## Pattern Detection Queries

에이전트가 유사 패턴을 탐지할 때 사용할 쿼리:

### Phantom Shares / Timing Attack
```
Grep("delegation|revocation|phantom|shares", glob="**/*.sol")
Grep("settlement|liquidat|callback", glob="**/*.sol")
```

### Credit/Debit Accumulation
```
Grep("credit|debit|leg|position", glob="**/*.sol")
Grep("solvency|collateral.*check", glob="**/*.sol")
```

### Bit Mask Overflow
```
Grep("<<|>>|pack|unpack|mask", glob="**/*.sol")
Grep("unchecked.*shift|overflow", glob="**/*.sol")
```

### Multi-Step Attack Surface
```
# auction → settlement 분리
Grep("start.*auction|settle.*auction|finalize", glob="**/*.sol")
# 다중 단계 상태 변경
Grep("pending|queued|execute", glob="**/*.sol")
```

---

## How to Use This Archive

### 에이전트 활용 방법

1. **Phase 1.5 (Agent Selection)**:
   - 프로토콜 유형에 따른 관련 패턴 참조
   - Panoptic-like → state-interaction + economic-attack
   - Megapot-like → state-interaction + access-control

2. **Phase 2 (Deep Analysis)**:
   - 유사 메커니즘 발견 시 이 아카이브의 공격 시나리오 참조
   - "이 프로토콜에서 F-61과 유사한 timing attack이 가능한가?"

3. **PoC Generation**:
   - 실제 유효한 발견의 공격 시나리오 구조 참조
   - Multi-step attack 구성 방법 참고

### 아카이브 확장

새로운 Code4rena 결과가 나오면 이 파일에 추가:

```markdown
## {Protocol Name} ({Date})

### {Finding ID}: {Title} ({Severity})

**카테고리**: {Category}

\`\`\`solidity
// 취약점 설명 및 코드 예시
\`\`\`

**탐지 포인트**:
- Point 1
- Point 2
```

---

## Future Work

1. **RLVR Integration**: 이 패턴들을 강화학습 피드백으로 활용
2. **Auto-Update**: Code4rena 결과 자동 수집 및 패턴 추출
3. **Pattern Clustering**: 유사 패턴 자동 분류
4. **Confidence Scoring**: 패턴 매칭 신뢰도 계산
