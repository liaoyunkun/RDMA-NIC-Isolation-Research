import numpy as np
OPTIMIZED = 1
SSC = 300
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
    p90 = np.percentile(ls_data, 90)
    print("LS P90 {}\n".format(p90))
    # write out bs latency
    global OPTIMIZED
    if (OPTIMIZED == 1):
        file_name = "res_out/optimized/bsLat_bs_" + str(bs_size_4k) + "_4k_iter_" \
                + str(iter_cnt) + "_ssc_{}.txt".format(SSC)
    else:
        file_name = "res_out/baseline/bsLat_bs_" + str(bs_size_4k) + "_4k_iter_" \
                + str(iter_cnt) + "_ssc_{}.txt".format(SSC)
    with open(file_name, "a+", encoding="utf-8") as f:
        for i in range(iter_cnt):
            f.write("{}\n".format(bs_data[i]))
    # write out ls latency
    if (OPTIMIZED == 1):
        file_name = "res_out/optimized/lsLat_bs_" + str(bs_size_4k) + "_4k_iter_" \
                + str(iter_cnt) + "_ssc_{}.txt".format(SSC)
    else:
        file_name = "res_out/baseline/lsLat_bs_" + str(bs_size_4k) + "_4k_iter_" \
                + str(iter_cnt) + "_ssc_{}.txt".format(SSC)
    with open(file_name, "a+", encoding="utf-8") as f:
        for i in range(iter_cnt):
            print("LS: {}\n".format(ls_data[i]))
            f.write("{}\n".format(ls_data[i]))
    
    return 0

def main():
    print_result(32, 1000)

if __name__ == "__main__":
    main()