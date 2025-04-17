# julia-fractal-fpga-hdmi
Display Julia Set fractals on an LCD using PYNQ Zynq SoC board

---
# Julia Set on FPGA (Verilog + Vivado)

- **프랙털 종류**: Julia Set  
- **구현 방식**: Verilog HDL  
- **플랫폼**: Xilinx FPGA (PYNQ-Z2 board)
- **디스플레이**: 1280x720 LCD 
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

- `HDMI_TOP.v`: 전체 시스템 Top module
- `HDMI_generator.v`: 전체 영상 생성 및 출력 파이프라인 통합, 하위 모듈로 `lcd_async_reset_ctrl`, `tmds_encoder_dvi`, `tmds_serializer_10to1` 포함
- `display_clocks.v`: 입력 클럭(100MHz)을 기반으로 HDMI 전송에 필요한 주파수의 클럭 신호 생성
- `display_timings.v`: 화면의 horizontal/vertical 좌표(x, y) 를 계산, 각 픽셀 좌표 생성
- `fixed_point_mul.v`: Q15.16 포맷의 실수/복소수 곱셈기
- `julia_gfx.v`: 그래픽 제어 최상위 모듈, 하위 모듈로 `julia_bram_ctrl.v`, `julia_iter.v` 포함
- `julia_bram_ctrl.v`: 계산된 반복 횟수를 바탕으로 BRAM에 색상 데이터 저장, 호출 제어
- `julia_iter.v`: Julia Set 반복 계산: `Z = Z² + C`
- `lcd_async_reset_ctrl.v`: LCD 모니터의 비동기 reset 신호 제어
- `tmds_encoder_dvi.v`: channel 3개를 제어
- `tmds_serializer_10to1.v`: 10:1 직렬 변환


```text
100MHz CLK
   │
   └──▶ display_clocks.v ──▶ pixel/TMDS clock
                                 │
                            display_timings.v ──▶ (x, y)
                                 │
                               julia_gfx.v
                                 │
                        ┌──────────────┐
                        │              ▼
               julia_bram_ctrl.v     ──▶ julia_iter.v (Z = Z² + C)
                        │              │
                        ▼              ▼
                 RGB 데이터         Iteration 결과
                        │
                  HDMI_generator.v
                        │
                TMDS Encoder + Serializer
        (tmds_encoder_dvi.v)  (tmds_serializer_10to1.v)
                        │
                       LCD

```
---

## 테스트 방법

1. Vivado에서 프로젝트 열기
2. 핀 설정 (`constraints/xdc.xdc`) 확인
3. Synthesis → Implementation → Bitstream 생성
4. FPGA 보드에 업로드 후 LCD 연결

---
