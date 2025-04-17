# verilog-pynq-fractal-display
Display Julia Set fractals on an LCD using PYNQ Zynq SoC board

---
# Julia Set on FPGA (Verilog + Vivado)

- **프랙털 종류**: Julia Set  
- **구현 방식**: Verilog HDL  
- **플랫폼**: Xilinx FPGA (PYNQ board)
- **디스플레이**: 1280x720 LCD / VGA 모니터  
- **좌표 매핑**: 화면 해상도 → 복소평면  
- **발산 판정**: 고정 소수점 기반 반복 연산  
- **컬러 매핑**: 반복 횟수 → 색상 값
  
---

# Directory
| 폴더 | 설명 |
|------|------|
| `bitstream/` | 생성된 `.bit` 파일 |
| `block_memory` | 메모리 모듈 (.xci) |
| `constraints/` | 핀 할당 파일 (.xdc) |
| `rtl/` | Verilog HDL 모듈 |
| `vivado_project/` | Vivado 프로젝트 파일 |

---

## 주요 모듈

- `julia_core.v`: Julia 수식 `Z = Z² + C` 반복 계산
- `complex_calc.v`: 복소수 연산 전용 모듈
- `pixel_driver.v`: 화면 좌표 ↔ 복소평면 매핑
- `top.v`: LCD 제어 및 통합

---

## 테스트 방법

1. Vivado에서 프로젝트 열기
2. 핀 설정 (`constraints/xdc.xdc`) 확인
3. Synthesis → Implementation → Bitstream 생성
4. FPGA 보드에 업로드 후 LCD 연결

---
