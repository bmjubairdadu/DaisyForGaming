#!/bin/bash
S=/root/daisy-build/kernel_source
ls $S/sound/soc/codecs/ | head -40
echo "---SRCH---"
grep -rln "msm8x16" $S/sound/ 2>/dev/null | head -10
echo "---MSM---"
ls $S/sound/soc/msm/ 2>/dev/null | head -20
