import numpy as np
BS1_MSG_SIZE_4K = [16, 32, 64, 128, 256]
def analyze_bs_bs_result():
    bs_0_bw = np.zeros(len(BS1_MSG_SIZE_4K))
    bs_1_bw = np.zeros(len(BS1_MSG_SIZE_4K))
    cnt = 0
    for bs1_size_4k in BS1_MSG_SIZE_4K:
        file_name = "res_out/optimized/bs_bw_" + str(bs1_size_4k) + "_4k" + ".txt"
        with open(file_name, "r", encoding="utf-8") as f:
            line_bs_0 = f.readline()[15:]
            line_bs_1 = f.readline()[15:]
            bs_0_bw[cnt] = eval(line_bs_0)
            bs_1_bw[cnt] = eval(line_bs_1)
        cnt += 1
    # print(bs_0_bw)
    # print("----------------")
    # print(bs_1_bw)
    ratio = bs_1_bw / bs_0_bw
    file_name = "res_out/optimized/bs_bw_ratio.txt"
    with open(file_name, "w", encoding="utf-8") as f:
        for i in range(len(BS1_MSG_SIZE_4K)):
            f.write("Message Size Ratio: {}, BW Ratio: {}\n".format(BS1_MSG_SIZE_4K[i], ratio[i]))

def main():
    analyze_bs_bs_result()

if __name__ == "__main__":
    main()