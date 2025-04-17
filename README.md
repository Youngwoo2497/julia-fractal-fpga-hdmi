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

- `HDMI_top.v`: 전체 시스템의 Top module, 하위 모듈로 `HDMI_generator`, `gfx`, `display_timings`, `display_clocks` 등을 포함하여 전체 영상 생성 및 출력 파이프라인 통합
- `display_clocks.v`: 입력 클럭(100MHz)을 기반으로 HDMI 전송에 필요한 주파수의 클럭 신호 생성
- `display_timings.v`: 화면의 horizontal/vertical 좌표(x, y) 를 계산, 각 픽셀에 대해 현재 위치 정보를 `gfx.v`로 전달
- `gfx.v`: 입력 좌표 `(x, y)`를 받아, 해당 픽셀에 출력할 **RGB 색상값**을 계산, 하위 모듈로 `BRAM_julia.v`, `julia_set.v` 포함
- `BRAM_julia.v`: 좌표 변환 + BRAM 컨트롤러, 계산된 반복 횟수를 바탕으로 색상값을 결정하여 BRAM에 저장, 출력
- `julia_set.v`: Julia 수식 `Z = Z² + C` 반복 계산 모듈
- `mul.v`: Q15.16 포맷의 실수/복소수 곱셈기


```text
100MHz CLK
   │
   └──▶ display_clocks.v ──▶ pixel/TMDS clock
                                 │
                            display_timings.v ──▶ (x, y)
                                 │
                               gfx.v
                                 │
                        ┌──────────────┐
                        │              ▼
               BRAM_julia.v     ──▶ julia_set.v (Z = Z² + C)
                        │              │
                        ▼              ▼
                 RGB 데이터         Iteration 결과
                        │
                  HDMI_generator.v
                        │
                TMDS Encoder + Serializer
                        │
                       LCD

---

## 테스트 방법

1. Vivado에서 프로젝트 열기
2. 핀 설정 (`constraints/xdc.xdc`) 확인
3. Synthesis → Implementation → Bitstream 생성
4. FPGA 보드에 업로드 후 LCD 연결

---
