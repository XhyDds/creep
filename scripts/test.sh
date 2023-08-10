#!/bin/bash
/bin/python3 ./Icache.py
/bin/python3 ./Dcache.py
/bin/python3 ./L2cache.py
/bin/python3 ./writebuf.py
/bin/python3 ./Write_FSM.py
/bin/python3 ./ghr.py
/bin/python3 ./ras.py
# diff $PWD/Icache.v ../L1cache/Icache.v
# diff $PWD/Dcache.v ../L1cache/Dcache.v
# diff $PWD/L2cache.v ../L2cache/L2cache.v
diff $PWD/WriteBuffer.v ../AXI/WriteBuffer.v
diff $PWD/Write_FSM.v ../AXI/Write_FSM.v
# diff $PWD/ghr.v ../predictor/ghr.v
# diff $PWD/ras.v ../predictor/ras.v
