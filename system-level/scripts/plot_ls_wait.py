# -*- coding: utf-8 -*-
"""
Created on Tue Apr 18 15:19:37 2023

@author: liao_
"""

import matplotlib.pyplot as plt
import numpy as np
from palettable.cartocolors.qualitative import Bold_10
color_map = Bold_10.hex_colors

FONT_SIZE = 16
MARKER_SIZE = 10
LINE_WIDTH = 2

SSC = 300
ITER_CNT = 10000
value_list = ["16K", "32K", "64K", "128K", "256K", "512K"]
bs_size_4k_list = [4, 8, 16, 32, 64, 128]
VALUE_CNT = len(bs_size_4k_list)

def fill_data(fname_pre, data_matrix, ssc):
    # e.g. fname_pre: ./res_out/baseline/lsLat_bs_
    for i in range(0, VALUE_CNT):
        fname = fname_pre + str(bs_size_4k_list[i]) + "_4k_iter_" + str(ITER_CNT) \
                + "_ssc_{}.txt".format(ssc)
        with open(fname, "r") as valf:
            for j in range(0, ITER_CNT):
                val = valf.readline()
                data_matrix[i,j] = eval(val) / (1000)  # convert Tick to ns

def get_stat(data_matrix):
    # calculate p50, p90 and p99, and std
    p50 = np.percentile(data_matrix, 50, axis=1)
    p90 = np.percentile(data_matrix, 90, axis=1)
    p99 = np.percentile(data_matrix, 99, axis=1)
    avg = np.average(data_matrix, axis=1)
    stat_matrix = np.vstack((p50, p90, p99, avg))
    return stat_matrix

baseline_wait = np.zeros((VALUE_CNT, ITER_CNT))
optimized_ssc_300 = np.zeros((VALUE_CNT, ITER_CNT))

fill_data("./res_out/baseline/ls_wait_", baseline_wait, SSC)
fill_data("./res_out/optimized/ls_wait_", optimized_ssc_300, SSC)

baseline_stat = get_stat(baseline_wait)
optimized_ssc_300_stat = get_stat(optimized_ssc_300)

# print(baseline_stat)
# print(optimized_ssc_300_stat)
print(baseline_stat[2, -1] / baseline_stat[2, 0])
print(optimized_ssc_300_stat[2, -1] / optimized_ssc_300_stat[2, 0])
fig2, ax2 = plt.subplots(figsize=(10, 4))
x = range(len(value_list))
# ax2.plot(x, baseline_stat[2,:], marker = '*', markersize = MARKER_SIZE, linewidth=LINE_WIDTH, color = "#f08c55", label = "HanGu-baseline")
# ax2.plot(x, optimized_ssc_300_stat[2,:], marker = 'o', markersize = MARKER_SIZE, linewidth=LINE_WIDTH, color = "#6ec8c8", label = "HanGu-isolated")
ax2.plot(x, baseline_stat[2,:], marker = '*', markersize = MARKER_SIZE, linewidth=LINE_WIDTH, color = color_map[0], label = "HanGu-baseline")
ax2.plot(x, optimized_ssc_300_stat[2,:], marker = 'o', markersize = MARKER_SIZE, linewidth=LINE_WIDTH, color = color_map[1], label = "HanGu-isolated")
ax2.set_xlabel('BS tenant message size (bytes)', fontsize=FONT_SIZE)
ax2.set_ylabel('P99 LS RX waiting latency (ns)', fontsize=FONT_SIZE)
ax2.set_xticks(x)
ax2.set_xticklabels(value_list, fontsize=FONT_SIZE)
ax2.tick_params(axis='y', labelsize =FONT_SIZE)
ax2.legend(fontsize=FONT_SIZE, frameon=False, ncols=2)

fig2.tight_layout()

plt.savefig("./res_out/figures/analysis_lat_RX_ls_wait_ssc_iter_{}.png".format(ITER_CNT))
plt.savefig("./res_out/figures/analysis_lat_RX_ls_wait_ssc_iter_{}.pdf".format(ITER_CNT))



