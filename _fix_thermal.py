import re

# ==== 1) DTS thermal trips: 80C/85C -> 68C/70C (throttle early, stay cool) ====
p = "/mnt/d/DaisyForGaming/arch/arm64/boot/dts/qcom/msm8953-thermal.dtsi"
src = open(p, encoding="utf-8", errors="surrogateescape").read()

# cpu_trip 80000 -> 68000
n1 = src.count("cpu_trip:cpu-trip {\n\t\t\t\ttemperature = <80000>;")
src = src.replace("cpu_trip:cpu-trip {\n\t\t\t\ttemperature = <80000>;",
                  "cpu_trip:cpu-trip {\n\t\t\t\ttemperature = <68000>;")
# pop_trip 80000 -> 70000
n2 = src.count("pop_trip: pop-trip {\n\t\t\t\ttemperature = <80000>;")
src = src.replace("pop_trip: pop-trip {\n\t\t\t\ttemperature = <80000>;",
                  "pop_trip: pop-trip {\n\t\t\t\ttemperature = <70000>;")
# gpu_trip0 85000 -> 70000
n3 = src.count("gpu_trip0: gpu-trip0 {\n\t\t\t\ttemperature = <85000>;")
src = src.replace("gpu_trip0: gpu-trip0 {\n\t\t\t\ttemperature = <85000>;",
                  "gpu_trip0: gpu-trip0 {\n\t\t\t\ttemperature = <70000>;")
# apc1 trips 90000 -> 75000 (cluster sensors)
n4 = src.count("temperature = <90000>;")
src = src.replace("temperature = <90000>;", "temperature = <75000>;")
open(p, "w", encoding="utf-8", errors="surrogateescape", newline="").write(src)
print("DTS: cpu=%d pop=%d gpu=%d apc1=%d" % (n1, n2, n3, n4))
