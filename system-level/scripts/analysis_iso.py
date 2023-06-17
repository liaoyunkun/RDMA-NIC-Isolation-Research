#!/usr/bin/python
import os
import time
import datetime
import numpy as np
import re

CLIENT_NUM = 1
QP_CACHE_CAP = 300
REORDER_CAP  = 64
QP_NUM_LIST = [1]
LS_BS = 0
OPTIMIZED = 1
SSC = 300  # SlicingEvent Schedule Cycles
ITER_LIST = [10000]
# BS_MSG_SIZE_4K = [64, 128, 256, 512, 1024]
BS_MSG_SIZE_4K = [4]
BS0_MSG_SIZE_4K = 32
# BS1_MSG_SIZE_4K = [32, 64, 128, 256, 512, 1024]
BS1_MSG_SIZE_4K = [1024]
# BS0_MSG_SIZE_4K = 1
# BS1_MSG_SIZE_4K = [64]
WR_TYPE = 0 # 0 -  rdma write; 1 - rdma read
PCIE_TYPE = "X16"
VERSION = "V1.5-final"
RECORD_FILENAME = "res_out/record-" + VERSION + "_QP_CACHE_CAP" + str(QP_CACHE_CAP) + "RECAP" + str(REORDER_CAP) + ".txt"

def change_param(qps_per_clt):
    file_data = ""
    with open("../tests/test-progs/hangu-rnic-isolated/src/librdma.h", "r", encoding="utf-8") as f:
        for line in f:
            if "#define TEST_QP_NUM" in line:
                line = "#define TEST_QP_NUM   " + str(qps_per_clt) + "\n"
            file_data += line

    with open("../tests/test-progs/hangu-rnic-isolated/src/librdma.h", "w", encoding="utf-8") as f:
        f.write(file_data)
    
    file_data = ""
    with open("../src/dev/rdma/hangu_rnic_defs.hh", "r", encoding="utf-8") as f:
        for line in f:
            if "#define QPN_NUM" in line:
                line = "#define QPN_NUM   (" + str(qps_per_clt) + " * " + str(CLIENT_NUM) + ")\n"
            file_data += line

    with open("../src/dev/rdma/hangu_rnic_defs.hh", "w", encoding="utf-8") as f:
        f.write(file_data)

def change_bs_size(bs_size_4k):
    file_data = ""
    with open("../tests/test-progs/hangu-rnic-isolated/src/librdma.h", "r", encoding="utf-8") as f:
        for line in f:
            if "#define MSG_SIZE_BS" in line:
                line = "#define MSG_SIZE_BS   " + str(bs_size_4k) + " * 4096" + "\n"
            file_data += line

    with open("../tests/test-progs/hangu-rnic-isolated/src/librdma.h", "w", encoding="utf-8") as f:
        f.write(file_data)

def change_bs_iter(bs_iter):
    file_data = ""
    with open("../tests/test-progs/hangu-rnic-isolated/src/librdma.h", "r", encoding="utf-8") as f:
        for line in f:
            if "#define ITER_BS" in line:
                line = "#define ITER_BS   " + str(bs_iter) + "\n"
            file_data += line

    with open("../tests/test-progs/hangu-rnic-isolated/src/librdma.h", "w", encoding="utf-8") as f:
        f.write(file_data)   

def change_ls_iter(ls_iter):
    file_data = ""
    with open("../tests/test-progs/hangu-rnic-isolated/src/librdma.h", "r", encoding="utf-8") as f:
        for line in f:
            if "#define ITER_LS" in line:
                line = "#define ITER_LS   " + str(ls_iter) + "\n"
            file_data += line

    with open("../tests/test-progs/hangu-rnic-isolated/src/librdma.h", "w", encoding="utf-8") as f:
        f.write(file_data) 

def change_test_mode(ls_bs):
    file_data = ""
    with open("../tests/test-progs/hangu-rnic-isolated/src/librdma.h", "r", encoding="utf-8") as f:
        for line in f:
            if "#define LS_BS" in line:
                line = "#define LS_BS   " + str(ls_bs) + "\n"
            file_data += line

    with open("../tests/test-progs/hangu-rnic-isolated/src/librdma.h", "w", encoding="utf-8") as f:
        f.write(file_data) 

def change_bs0_size(bs0_size_4k):
    file_data = ""
    with open("../tests/test-progs/hangu-rnic-isolated/src/librdma.h", "r", encoding="utf-8") as f:
        for line in f:
            if "#define BS0_MSG_SIZE" in line:
                line = "#define BS0_MSG_SIZE   " + str(bs0_size_4k) + " * 4096" + "\n"
            file_data += line

    with open("../tests/test-progs/hangu-rnic-isolated/src/librdma.h", "w", encoding="utf-8") as f:
        f.write(file_data)

def change_bs1_size(bs1_size_4k):
    file_data = ""
    with open("../tests/test-progs/hangu-rnic-isolated/src/librdma.h", "r", encoding="utf-8") as f:
        for line in f:
            if "#define BS1_MSG_SIZE" in line:
                line = "#define BS1_MSG_SIZE   " + str(bs1_size_4k) + " * 4096" + "\n"
            file_data += line

    with open("../tests/test-progs/hangu-rnic-isolated/src/librdma.h", "w", encoding="utf-8") as f:
        f.write(file_data)
    
def change_opt_cfg(opt):
    file_data = ""
    with open("../src/dev/rdma/hangu_rnic_defs.hh", "r", encoding="utf-8") as f:
        for line in f:
            if "#define OPTIMIZED" in line:
                if (opt == 1):
                    pass
                else:
                    line = "#define BASELINE 1\n"
            if "#define BASELINE" in line:
                if (opt == 1):
                    line = "#define OPTIMIZED 1\n"
                else:
                    pass
            file_data += line
    with open("../src/dev/rdma/hangu_rnic_defs.hh", "w", encoding="utf-8") as f:
        f.write(file_data)

def change_ssc_cfg(cfg):
    file_data = ""
    # SLICING_SCHEDULE_CYCLE
    with open("../src/dev/rdma/hangu_rnic_defs.hh", "r", encoding="utf-8") as f:
        for line in f:
            if "#define SLICING_SCHEDULE_CYCLE" in line:
                line = "#define SLICING_SCHEDULE_CYCLE   " + str(cfg) + "\n"
            file_data += line

    with open("../src/dev/rdma/hangu_rnic_defs.hh", "w", encoding="utf-8") as f:
        f.write(file_data)

def execute_program(node_num, qpc_cache_cap, reorder_cap):
    return os.system("python3 run_hangu_iso.py " + str(node_num) + " " + str(qpc_cache_cap) + " " + str(reorder_cap) + " " + str(WR_TYPE))

def print_result(bs_size_4k, iter_cnt):
    ls_cnt = 0
    ls_lat = ""
    ls_data = np.zeros(iter_cnt)
    bs_cnt = 0
    bs_lat = ""
    bs_data = np.zeros(iter_cnt)
    with open("res_out/rnic_sys_test.txt") as f:
        for line in f.readlines():
            if "BS:" in line:
                bs_lat = line[4:-3]
                bs_data[bs_cnt] = eval(bs_lat)
                bs_cnt += 1
            if "LS:" in line:
                ls_lat = line[4:-3]
                ls_data[ls_cnt] = eval(ls_lat)
                ls_cnt += 1
    # write out bs latency
    global OPTIMIZED
    if (OPTIMIZED == 1):
        file_name = "res_out/optimized/bsLat_bs_" + str(bs_size_4k) + "_4k_iter_" \
                + str(iter_cnt) + "_ssc_{}.txt".format(SSC)
    else:
        file_name = "res_out/baseline/bsLat_bs_" + str(bs_size_4k) + "_4k_iter_" \
                + str(iter_cnt) + "_ssc_{}.txt".format(SSC)
    with open(file_name, "w", encoding="utf-8") as f:
        for i in range(iter_cnt):
            f.write("{}\n".format(bs_data[i]))
    # write out ls latency
    if (OPTIMIZED == 1):
        file_name = "res_out/optimized/lsLat_bs_" + str(bs_size_4k) + "_4k_iter_" \
                + str(iter_cnt) + "_ssc_{}.txt".format(SSC)
    else:
        file_name = "res_out/baseline/lsLat_bs_" + str(bs_size_4k) + "_4k_iter_" \
                + str(iter_cnt) + "_ssc_{}.txt".format(SSC)
    with open(file_name, "w", encoding="utf-8") as f:
        for i in range(iter_cnt):
            f.write("{}\n".format(ls_data[i]))
    
    return 0

def print_bs_bs_result(bs1_size_4k):
    bs0_bw = ""
    bs1_bw = ""
    with open("res_out/rnic_sys_test.txt") as f:
        for line in f.readlines():
            if "BS_0 Bandwidth" in line:
                bs0_bw = line
            if "BS_1 Bandwidth" in line:
                bs1_bw = line
    global OPTIMIZED
    if (OPTIMIZED == 1):
        file_name = "res_out/optimized/bs_bw_bs0_" + str(BS0_MSG_SIZE_4K) + "_4k_" \
                    + "bs1_" + str(bs1_size_4k) + "_4k" \
                    + "_ssc_{}.txt".format(SSC)
    else:
        file_name = "res_out/baseline/bs_bw_bs0_" + str(BS0_MSG_SIZE_4K) + "_4k_" \
                    + "bs1_" + str(bs1_size_4k) + "_4k" \
                    + "_ssc_{}.txt".format(SSC)
    with open(file_name, "w", encoding="utf-8") as f:
        f.write(bs0_bw)
        f.write(bs1_bw)

def parse_rx_ls_wait_lat(bs_size_4k, iter_cnt):
    inTick = np.zeros(iter_cnt)
    in_idx = 0
    outTick = np.zeros(iter_cnt)
    out_idx = 0
    with open("res_out/rnic_sys_test.txt", "r") as f:
        for line in f.readlines():
            if "LS ONLY PACKET IN:" in line:
                x = re.search("LS ONLY PACKET IN:", line)
                inTick[in_idx] = eval(line[x.end()+1:])
                in_idx += 1
            if "LS ONLY PACKET OUT:" in line:
                x = re.search("LS ONLY PACKET OUT:", line)
                outTick[out_idx] = eval(line[x.end()+1:])
                out_idx += 1
    global OPTIMIZED
    global SSC
    if (OPTIMIZED == 1):
        file_name = "res_out/optimized/ls_wait_" + str(bs_size_4k) + "_4k_iter_" \
                + str(iter_cnt) + "_ssc_{}.txt".format(SSC)
    else:
        file_name = "res_out/baseline/ls_wait_" + str(bs_size_4k) + "_4k_iter_" \
                + str(iter_cnt) + "_ssc_{}.txt".format(SSC)
    with open(file_name, "w", encoding="utf-8") as f:
        for i in range(iter_cnt):
            f.write("{}\n".format(outTick[i] - inTick[i]))
    
                
def analyze_bs_bs_result():
    bs_0_bw = np.zeros(len(BS1_MSG_SIZE_4K))
    bs_1_bw = np.zeros(len(BS1_MSG_SIZE_4K))
    cnt = 0
    global OPTIMIZED
    for bs1_size_4k in BS1_MSG_SIZE_4K:
        if (OPTIMIZED == 1):
            file_name = "res_out/optimized/bs_bw_bs0_" + str(BS0_MSG_SIZE_4K) + "_4k_" \
                    + "bs1_" + str(bs1_size_4k) + "_4k" \
                    + "_ssc_{}.txt".format(SSC)
        else:
            file_name = "res_out/baseline/bs_bw_bs0_" + str(BS0_MSG_SIZE_4K) + "_4k_" \
                    + "bs1_" + str(bs1_size_4k) + "_4k" \
                    + "_ssc_{}.txt".format(SSC)
        with open(file_name, "r", encoding="utf-8") as f:
            line_bs_0 = f.readline()[15:]
            line_bs_1 = f.readline()[15:]
            bs_0_bw[cnt] = eval(line_bs_0)
            bs_1_bw[cnt] = eval(line_bs_1)
        cnt += 1
    ratio = bs_1_bw / bs_0_bw
    if (OPTIMIZED == 1):
        file_name = "res_out/optimized/bs_bw_ratio_bs0_{}_4k_ssc_{}.txt".format(BS0_MSG_SIZE_4K, SSC)
    else:
        file_name = "res_out/baseline/bs_bw_ratio_bs0_{}_4k_ssc_{}.txt".format(BS0_MSG_SIZE_4K, SSC)
    with open(file_name, "w", encoding="utf-8") as f:
        for i in range(len(BS1_MSG_SIZE_4K)):
            f.write("Message Size Ratio: {}, BW Ratio: {}\n".format(BS1_MSG_SIZE_4K[i], ratio[i]))
def exp():
    for qps_per_clt in QP_NUM_LIST:
        if (LS_BS == 1):
            for bs_size_4k in BS_MSG_SIZE_4K:
                for iter_cnt in ITER_LIST:
                    # Change parameter realted to the simulation
                    change_param(qps_per_clt)
                    change_test_mode(LS_BS)
                    change_bs_size(bs_size_4k)
                    change_bs_iter(iter_cnt)
                    change_ls_iter(iter_cnt)
                    # execute the program
                    if execute_program(CLIENT_NUM + 1, QP_CACHE_CAP, REORDER_CAP) != 0:
                        print("\033[0;31;40mProgram execution error! %d\033[0m" % (qps_per_clt))
                        return 1
                    print_result(bs_size_4k, iter_cnt)
                    parse_rx_ls_wait_lat(bs_size_4k, iter_cnt)
        else:
            # BS-BS
            change_param(qps_per_clt)
            change_test_mode(LS_BS)
            change_bs0_size(BS0_MSG_SIZE_4K)
            for bs1_size_4k in BS1_MSG_SIZE_4K:
                assert(bs1_size_4k >= BS0_MSG_SIZE_4K)
                change_bs1_size(bs1_size_4k)
                # execute the program
                if execute_program(CLIENT_NUM + 1, QP_CACHE_CAP, REORDER_CAP) != 0:
                    print("\033[0;31;40mProgram execution error! %d\033[0m" % (qps_per_clt))
                    return 1
                print_bs_bs_result(bs1_size_4k)
            analyze_bs_bs_result()
def main():
    global OPTIMIZED
    global SSC
    global LS_BS
    run_time = []
    SSC = 300
    change_ssc_cfg(SSC)
    # # LS_BS Baseline
    LS_BS = 1
    OPTIMIZED = 0
    change_opt_cfg(OPTIMIZED)
    start_time = datetime.datetime.now()
    exp()
    end_time = datetime.datetime.now()
    run_time.append((start_time, end_time))
    # # LS_BS Optimized
    LS_BS = 1
    OPTIMIZED = 1
    change_opt_cfg(OPTIMIZED)
    start_time = datetime.datetime.now()
    exp()
    end_time = datetime.datetime.now()
    run_time.append((start_time, end_time))

    # SSC = 100
    # LS_BS = 1
    # OPTIMIZED = 1
    # change_opt_cfg(OPTIMIZED)
    # start_time = datetime.datetime.now()
    # exp()
    # end_time = datetime.datetime.now()
    # run_time.append((start_time, end_time))
    # BS_BS Baseline
    # LS_BS = 0
    # OPTIMIZED = 0
    # change_opt_cfg(OPTIMIZED)
    # start_time = datetime.datetime.now()
    # exp()
    # end_time = datetime.datetime.now()
    # run_time.append((start_time, end_time))
    # # # BS_BS Optimized
    # LS_BS = 0
    # OPTIMIZED = 1
    # change_opt_cfg(OPTIMIZED)
    # start_time = datetime.datetime.now()
    # exp()
    # end_time = datetime.datetime.now()
    # run_time.append((start_time, end_time))
    print("-------------run time---------------\n")
    for i in range(len(run_time)):
        print("exp_{}, run for {} minutes\n".format(i, ((run_time[i][1] - run_time[i][0]) / 60)))
    print("------------------------------------\n")
if __name__ == "__main__":
    main()
