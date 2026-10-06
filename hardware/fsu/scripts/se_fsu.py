# gem5 config wrapper: sets the FSU lookup latency (env FSU_LAT, e.g. "1ns") then runs se.py.
# Usage: gem5.opt scripts/se_fsu.py <se.py args>   (FSU build only)
import os
import runpy
import sys

from m5.objects import MemCtrl

lat = os.environ.get("FSU_LAT")
if lat:
    MemCtrl.fsu_lookup_latency = lat
root = os.environ["GEM5_ROOT"]
sys.path.insert(0, os.path.join(root, "configs"))
se = os.path.join(root, "configs/deprecated/example/se.py")
sys.argv[0] = se
runpy.run_path(se, run_name="__m5_main__")
