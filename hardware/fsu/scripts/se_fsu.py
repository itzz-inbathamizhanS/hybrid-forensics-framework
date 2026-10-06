# gem5 config wrapper: sets the FSU lookup latency (env FSU_LAT, e.g. "1ns") then runs se.py.
# Usage: gem5.opt scripts/se_fsu.py <se.py args>   (FSU build only)
import os
import runpy
import sys

from m5.objects import MemCtrl

lat = os.environ.get("FSU_LAT")
if lat:
    MemCtrl.fsu_lookup_latency = lat
se = os.path.join(os.environ["GEM5_ROOT"], "configs/deprecated/example/se.py")
sys.argv[0] = se
runpy.run_path(se, run_name="__m5_main__")
