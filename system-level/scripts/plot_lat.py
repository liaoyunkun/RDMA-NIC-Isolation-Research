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
value_list = ["4K", "8K", "16K", "32K", "64K", "128K"]
bs_size_4k_list = [1, 2, 4, 8, 16, 32]
VALUE_CNT = len(bs_size_4k_list)

single_p50 = 0.0
single_p90 = 0.0
single_p99 = 0.0

def cal_single():
    single_data = np.zeros(1000)
    fname = "./res_out/lsLat_single.txt"
    with open(fname, "r") as valf:
        for i in range(0, 1000):
            val = valf.readline()
            single_data[i] = eval(val)
    single_p50 = np.percentile(single_data, 50)
    single_p90 = np.percentile(single_data, 90)
    single_p99 = np.percentile(single_data, 99)
    single_avg = np.average(single_data)
    
    return (single_p50, single_p90, single_p99, single_avg)

def fill_data(fname_pre, data_matrix, ssc):
    # e.g. fname_pre: ./res_out/baseline/lsLat_bs_
    for i in range(0, VALUE_CNT):
        fname = fname_pre + str(bs_size_4k_list[i]) + "_4k_iter_" + str(ITER_CNT) \
                + "_ssc_{}.txt".format(ssc)
        with open(fname, "r") as valf:
            for j in range(0, ITER_CNT):
                val = valf.readline()
                data_matrix[i,j] = eval(val)

def get_stat(data_matrix):
    # calculate p50, p90 and p99, and std
    p50 = np.percentile(data_matrix, 50, axis=1)
    p90 = np.percentile(data_matrix, 90, axis=1)
    p99 = np.percentile(data_matrix, 99, axis=1)
    avg = np.average(data_matrix, axis=1)
    stat_matrix = np.vstack((p50, p90, p99, avg))
    return stat_matrix

baseline_data = np.zeros((VALUE_CNT, ITER_CNT))
optimized_data_ssc_300 = np.zeros((VALUE_CNT, ITER_CNT))
optimized_data_ssc_200 = np.zeros((VALUE_CNT, ITER_CNT))
optimized_data_ssc_150 = np.zeros((VALUE_CNT, ITER_CNT))
optimized_data_ssc_100 = np.zeros((VALUE_CNT, ITER_CNT))
optimized_data_ssc_75 = np.zeros((VALUE_CNT, ITER_CNT))

fill_data("./res_out/baseline/lsLat_bs_", baseline_data, 300)
fill_data("./res_out/optimized/lsLat_bs_", optimized_data_ssc_300, 300)
fill_data("./res_out/optimized/lsLat_bs_", optimized_data_ssc_150, 150)
fill_data("./res_out/optimized/lsLat_bs_", optimized_data_ssc_200, 200)
fill_data("./res_out/optimized/lsLat_bs_", optimized_data_ssc_100, 100)
fill_data("./res_out/optimized/lsLat_bs_", optimized_data_ssc_75, 75)
#print(baseline_data)
baseline_stat = get_stat(baseline_data)
optimized_ssc_300_stat = get_stat(optimized_data_ssc_300)
optimized_ssc_200_stat = get_stat(optimized_data_ssc_200)
optimized_ssc_150_stat = get_stat(optimized_data_ssc_150)
optimized_ssc_100_stat = get_stat(optimized_data_ssc_100)
optimized_ssc_75_stat = get_stat(optimized_data_ssc_75)

(single_p50, single_p90, single_p99, single_avg) = cal_single()

baseline_p50_inc = baseline_stat[0,:] / single_p50
baseline_p90_inc = baseline_stat[1,:] / single_p90
baseline_p99_inc = baseline_stat[2,:] / single_p99
baseline_avg_inc = baseline_stat[3,:] / single_avg

optimized_ssc_300_p50_inc = optimized_ssc_300_stat[0,:] / single_p50
optimized_ssc_300_p90_inc = optimized_ssc_300_stat[1,:] / single_p90
optimized_ssc_300_p99_inc = optimized_ssc_300_stat[2,:] / single_p99
optimized_ssc_300_avg_inc = optimized_ssc_300_stat[3,:] / single_avg

optimized_ssc_200_p50_inc = optimized_ssc_200_stat[0,:] / single_p50
optimized_ssc_200_p90_inc = optimized_ssc_200_stat[1,:] / single_p90
optimized_ssc_200_p99_inc = optimized_ssc_200_stat[2,:] / single_p99
optimized_ssc_200_avg_inc = optimized_ssc_200_stat[3,:] / single_avg

optimized_ssc_150_p50_inc = optimized_ssc_150_stat[0,:] / single_p50
optimized_ssc_150_p90_inc = optimized_ssc_150_stat[1,:] / single_p90
optimized_ssc_150_p99_inc = optimized_ssc_150_stat[2,:] / single_p99
optimized_ssc_150_avg_inc = optimized_ssc_150_stat[3,:] / single_avg

optimized_ssc_100_p50_inc = optimized_ssc_100_stat[0,:] / single_p50
optimized_ssc_100_p90_inc = optimized_ssc_100_stat[1,:] / single_p90
optimized_ssc_100_p99_inc = optimized_ssc_100_stat[2,:] / single_p99
optimized_ssc_100_avg_inc = optimized_ssc_100_stat[3,:] / single_avg

optimized_ssc_75_p50_inc = optimized_ssc_75_stat[0,:] / single_p50
optimized_ssc_75_p90_inc = optimized_ssc_75_stat[1,:] / single_p90
optimized_ssc_75_p99_inc = optimized_ssc_75_stat[2,:] / single_p99
optimized_ssc_75_avg_inc = optimized_ssc_75_stat[3,:] / single_avg

print("+++++++++++++++++++++++++\n")
print("HanGu-isolated improvement\n")
print("p90:\n")
hanguImprove_p90_ssc_300 = baseline_p90_inc / optimized_ssc_300_p90_inc
print(hanguImprove_p90_ssc_300)
print("p99:\n")
hanguImprove_p99_ssc_300 = baseline_p99_inc / optimized_ssc_300_p99_inc
hanguImprove_p99_ssc_200 = baseline_p99_inc / optimized_ssc_200_p99_inc
hanguImprove_p99_ssc_150 = baseline_p99_inc / optimized_ssc_150_p99_inc
hanguImprove_p99_ssc_100 = baseline_p99_inc / optimized_ssc_100_p99_inc
hanguImprove_p99_ssc_75 = baseline_p99_inc / optimized_ssc_75_p99_inc

print(hanguImprove_p99_ssc_300)
print("avg:\n")
hanguImprove_avg_ssc_300 = baseline_avg_inc / optimized_ssc_300_avg_inc
print(hanguImprove_avg_ssc_300)
print("+++++++++++++++++++++++++\n")

fig0, ax0 = plt.subplots(figsize=(10, 4))
x = range(len(value_list))
# ax0.plot(x, baseline_avg_inc, marker = '*', markersize = MARKER_SIZE, linewidth=LINE_WIDTH, color = "#c489ff", label = "HanGu-baseline Avg")
# ax0.plot(x, baseline_p90_inc, marker = '+', markersize = MARKER_SIZE, linewidth=LINE_WIDTH, color = "#ffe699", label = "HanGu-baseline P90")
# ax0.plot(x, baseline_p99_inc, marker = 'o', markersize = MARKER_SIZE, linewidth=LINE_WIDTH, color = "#bfbfbf", label = "HanGu-baseline P99")
# ax0.plot(x, optimized_ssc_300_avg_inc, linestyle = 'dashed', marker = 'v', markersize = MARKER_SIZE, linewidth=LINE_WIDTH, color = "#ff9999", label = "HanGu-isolated Avg")
# ax0.plot(x, optimized_ssc_300_p90_inc, linestyle = 'dashed', marker = '^', markersize = MARKER_SIZE, linewidth=LINE_WIDTH, color = "#b4c7e7", label = "HanGu-isolated P90")
# ax0.plot(x, optimized_ssc_300_p99_inc, linestyle = 'dashed', marker = '>', markersize = MARKER_SIZE, linewidth=LINE_WIDTH, color = "#a9d18e", label = "HanGu-isolated P99")
ax0.plot(x, baseline_avg_inc, marker = '*', markersize = MARKER_SIZE, linewidth=LINE_WIDTH, color = color_map[0], label = "HanGu-baseline Avg")
ax0.plot(x, baseline_p90_inc, marker = '+', markersize = MARKER_SIZE, linewidth=LINE_WIDTH, color = color_map[1], label = "HanGu-baseline P90")
ax0.plot(x, baseline_p99_inc, marker = 'o', markersize = MARKER_SIZE, linewidth=LINE_WIDTH, color = color_map[2], label = "HanGu-baseline P99")
ax0.plot(x, optimized_ssc_300_avg_inc, linestyle = 'dashed', marker = 'v', markersize = MARKER_SIZE, linewidth=LINE_WIDTH, color = color_map[3], label = "HanGu-isolated Avg")
ax0.plot(x, optimized_ssc_300_p90_inc, linestyle = 'dashed', marker = '^', markersize = MARKER_SIZE, linewidth=LINE_WIDTH, color = color_map[4], label = "HanGu-isolated P90")
ax0.plot(x, optimized_ssc_300_p99_inc, linestyle = 'dashed', marker = '>', markersize = MARKER_SIZE, linewidth=LINE_WIDTH, color = color_map[5], label = "HanGu-isolated P99")
ax0.set_xlabel('BS tenant message size (bytes)', fontsize=FONT_SIZE)
ax0.set_ylabel('Latency increase \n ratio', fontsize=FONT_SIZE)
ax0.set_xticks(x)
ax0.set_xticklabels(value_list, fontsize=FONT_SIZE)
ax0.tick_params(axis='y', labelsize =FONT_SIZE)
ax0.legend(fontsize=FONT_SIZE, frameon=False, ncols=2)

fig0.tight_layout()
plt.subplots_adjust(left=0.125)
plt.savefig("./res_out/figures/analysis_lat_ssc_{}_iter_{}.png".format(SSC, ITER_CNT))
plt.savefig("./res_out/figures/analysis_lat_ssc_{}_iter_{}.pdf".format(SSC, ITER_CNT))


fig1, ax1 = plt.subplots(figsize=(10, 4))
x = range(len(value_list))
# ax1.plot(x, hanguImprove_p90_ssc_300, marker = '*', markersize = MARKER_SIZE, linewidth=LINE_WIDTH, color = "#6ec8c8", label = "Avg")
# ax1.plot(x, hanguImprove_p99_ssc_300, marker = '+', markersize = MARKER_SIZE, linewidth=LINE_WIDTH, color = "#6496d2", label = "P90")
# ax1.plot(x, hanguImprove_avg_ssc_300, marker = 'o', markersize = MARKER_SIZE, linewidth=LINE_WIDTH, color = "#78be96", label = "P99")
ax1.plot(x, hanguImprove_p90_ssc_300, marker = '*', markersize = MARKER_SIZE, linewidth=LINE_WIDTH, color = color_map[0], label = "Avg")
ax1.plot(x, hanguImprove_p99_ssc_300, marker = '+', markersize = MARKER_SIZE, linewidth=LINE_WIDTH, color = color_map[1], label = "P90")
ax1.plot(x, hanguImprove_avg_ssc_300, marker = 'o', markersize = MARKER_SIZE, linewidth=LINE_WIDTH, color = color_map[2], label = "P99")
ax1.set_xlabel('BS tenant message size (bytes)', fontsize=FONT_SIZE)
ax1.set_ylabel('Hangu-isolated \n improvement', fontsize=FONT_SIZE)
ax1.set_xticks(x)
ax1.set_xticklabels(value_list, fontsize=FONT_SIZE)
ax1.tick_params(axis='y', labelsize =FONT_SIZE)
ax1.legend(fontsize=FONT_SIZE, frameon=False, ncols=2)

fig1.tight_layout()

plt.savefig("./res_out/figures/analysis_lat_improve_ssc_{}_iter_{}.png".format(SSC, ITER_CNT))
plt.savefig("./res_out/figures/analysis_lat_improve_ssc_{}_iter_{}.pdf".format(SSC, ITER_CNT))


fig2, ax2 = plt.subplots(figsize=(10, 4))
x = range(len(value_list))
# ax2.plot(x, hanguImprove_p99_ssc_75, marker = '*',  markersize = MARKER_SIZE, linewidth=LINE_WIDTH, color = "#6ec8c8", label = "BS_SSC = 75")
# ax2.plot(x, hanguImprove_p99_ssc_150, marker = '+', markersize = MARKER_SIZE, linewidth=LINE_WIDTH, color = "#6496d2", label = "BS_SSC = 150")
# ax2.plot(x, hanguImprove_p99_ssc_300, marker = 'o', markersize = MARKER_SIZE, linewidth=LINE_WIDTH, color = "#78be96", label = "BS_SSC = 300")
ax2.plot(x, hanguImprove_p99_ssc_75, marker = '*',  markersize = MARKER_SIZE, linewidth=LINE_WIDTH, color = color_map[0], label = "BS_SSC = 75")
ax2.plot(x, hanguImprove_p99_ssc_150, marker = '+', markersize = MARKER_SIZE, linewidth=LINE_WIDTH, color = color_map[1], label = "BS_SSC = 150")
ax2.plot(x, hanguImprove_p99_ssc_300, marker = 'o', markersize = MARKER_SIZE, linewidth=LINE_WIDTH, color = color_map[2], label = "BS_SSC = 300")
ax2.set_xlabel('BS tenant message size (bytes)', fontsize=FONT_SIZE)
ax2.set_ylabel('Hangu-isolated \n improvement', fontsize=FONT_SIZE)
ax2.set_xticks(x)
ax2.set_xticklabels(value_list, fontsize=FONT_SIZE)
ax2.tick_params(axis='y', labelsize =FONT_SIZE)
ax2.legend(fontsize=FONT_SIZE, frameon=False, ncols=2)

fig2.tight_layout()

plt.savefig("./res_out/figures/analysis_lat_change_ssc_iter_{}.png".format(ITER_CNT))
plt.savefig("./res_out/figures/analysis_lat_change_ssc_iter_{}.pdf".format(ITER_CNT))