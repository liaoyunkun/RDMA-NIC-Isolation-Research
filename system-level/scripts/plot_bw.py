# -*- coding: utf-8 -*-
"""
Created on Thu Apr 20 13:00:31 2023

@author: liao_
"""
import matplotlib.pyplot as plt
import numpy as np
from palettable.cartocolors.qualitative import Bold_10
color_map = Bold_10.hex_colors

FONT_SIZE = 16
LINE_WIDTH = 2
MARKER_SIZE = 10
SSC = 300
BS0_MSG_SIZE_4K = 32
BS0_MSG_SIZE = BS0_MSG_SIZE_4K * 4 #KB
SAMPLE_CNT = 5
bs1_msg_size_4k = []

for i in range(SAMPLE_CNT):
    bs1_msg_size_4k.append(BS0_MSG_SIZE_4K * pow(2, i))

bs1_msg_size_list = []
ideal_isolation = []

for i in range(len(bs1_msg_size_4k)):
    if (bs1_msg_size_4k[i] * 4 >= 1024):
        bs1_msg_size_list.append("{}M".format(int(bs1_msg_size_4k[i] * 4 / 1024)))
    else:
        bs1_msg_size_list.append("{}K".format(bs1_msg_size_4k[i] * 4))
    ideal_isolation.append(1)
    
base_bs0_bw = np.zeros(SAMPLE_CNT)
base_bs1_bw = np.zeros(SAMPLE_CNT)
base_bw_ratio = np.zeros(SAMPLE_CNT)

opt_bs0_bw = np.zeros(SAMPLE_CNT)
opt_bs1_bw = np.zeros(SAMPLE_CNT)
opt_bw_ratio = np.zeros(SAMPLE_CNT)

opt_bs0_ssc_600_bw = np.zeros(SAMPLE_CNT)
opt_bs1_ssc_600_bw = np.zeros(SAMPLE_CNT)
opt_bw_ssc_600_ratio = np.zeros(SAMPLE_CNT)

# read baseline
for i in range(SAMPLE_CNT):
    filename = "./res_out/baseline/bs_bw_bs0_{}_4k_bs1_{}_4k_ssc_{}.txt".\
            format(BS0_MSG_SIZE_4K, bs1_msg_size_4k[i], SSC)
    with open(filename, "r") as f:
        line_bs_0 = f.readline()[15:]
        line_bs_1 = f.readline()[15:]
        base_bs0_bw[i] = eval(line_bs_0) / 1000
        base_bs1_bw[i] = eval(line_bs_1) / 1000
# read optimized
for i in range(SAMPLE_CNT):
    filename = "./res_out/optimized/bs_bw_bs0_{}_4k_bs1_{}_4k_ssc_{}.txt".\
            format(BS0_MSG_SIZE_4K, bs1_msg_size_4k[i], SSC)
    with open(filename, "r") as f:
        line_bs_0 = f.readline()[15:]
        line_bs_1 = f.readline()[15:]
        opt_bs0_bw[i] = eval(line_bs_0) / 1000
        opt_bs1_bw[i] = eval(line_bs_1) / 1000

for i in range(SAMPLE_CNT):
    filename = "./res_out/optimized/bs_bw_bs0_{}_4k_bs1_{}_4k_ssc_{}.txt".\
            format(BS0_MSG_SIZE_4K, bs1_msg_size_4k[i], 600)
    with open(filename, "r") as f:
        line_bs_0 = f.readline()[15:]
        line_bs_1 = f.readline()[15:]
        opt_bs0_ssc_600_bw[i] = eval(line_bs_0) / 1000
        opt_bs1_ssc_600_bw[i] = eval(line_bs_1) / 1000
        

base_bw_ratio = base_bs1_bw / base_bs0_bw
opt_bw_ratio = opt_bs1_bw / opt_bs0_bw
opt_bw_ssc_600_ratio = opt_bs1_ssc_600_bw / opt_bs0_ssc_600_bw
print("------------------------------\n")
print(base_bw_ratio)
print(opt_bw_ratio)
print(base_bw_ratio / opt_bw_ratio)
print("------------------------------\n")

fig0, ax0 = plt.subplots(figsize=(10, 4))
x = range(len(bs1_msg_size_list))
# ax0.plot(x, base_bw_ratio, marker = '>',   markersize = MARKER_SIZE, linewidth=LINE_WIDTH, color = "#6ec8c8", label = "HanGu-baseline")
# ax0.plot(x, opt_bw_ratio, marker = '<',    markersize = MARKER_SIZE, linewidth=LINE_WIDTH, color = "#6496d2", label = "HanGu-isolated")
# ax0.plot(x, ideal_isolation, marker = '^', markersize = MARKER_SIZE, linewidth=LINE_WIDTH, color = "#78be96", label = "Ideal isolation")
ax0.plot(x, base_bw_ratio, marker = '>',   markersize = MARKER_SIZE, linewidth=LINE_WIDTH, color = color_map[0], label = "HanGu-baseline")
ax0.plot(x, opt_bw_ratio, marker = '<',    markersize = MARKER_SIZE, linewidth=LINE_WIDTH, color = color_map[1], label = "HanGu-isolated")
ax0.plot(x, ideal_isolation, marker = '^', markersize = MARKER_SIZE, linewidth=LINE_WIDTH, color = color_map[2], label = "Ideal isolation")
ax0.set_xlabel('BS tenant-1 message size (bytes)', fontsize=FONT_SIZE)
ax0.set_ylabel('Bandwidth ratio: \n tenant-1 / tenant-0', fontsize=FONT_SIZE)
ax0.set_xticks(x)
ax0.set_xticklabels(bs1_msg_size_list, fontsize=FONT_SIZE)
ax0.tick_params(axis='y', labelsize =FONT_SIZE)
ax0.legend(fontsize=FONT_SIZE, frameon=False)
# plt.title("Ratio of achievable bandwidth, message size of BS Flow-0 is 128KB", fontsize=FONT_SIZE)
fig0.tight_layout()
plt.subplots_adjust(left=0.125)
plt.savefig("./res_out/figures/analysis_bw_ratio_bs0_{}_4k_ssc_{}.png".\
            format(BS0_MSG_SIZE_4K, SSC))
plt.savefig("./res_out/figures/analysis_bw_ratio_bs0_{}_4k_ssc_{}.pdf".\
            format(BS0_MSG_SIZE_4K, SSC))

fig0, ax0 = plt.subplots(figsize=(10, 4))
x = range(len(bs1_msg_size_list))
# ax0.plot(x, opt_bw_ssc_600_ratio, marker = '>',   markersize = MARKER_SIZE, linewidth=LINE_WIDTH, color = "#6ec8c8", label = "HanGu-isolated, BS_SSC = 600")
# ax0.plot(x, opt_bw_ratio, marker = '<',           markersize = MARKER_SIZE, linewidth=LINE_WIDTH, color = "#6496d2", label = "HanGu-isolated, BS_SSC = 300")
# ax0.plot(x, ideal_isolation, marker = '^',        markersize = MARKER_SIZE, linewidth=LINE_WIDTH, color = "#78be96", label = "Ideal isolation")
ax0.plot(x, opt_bw_ssc_600_ratio, marker = '>',   markersize = MARKER_SIZE, linewidth=LINE_WIDTH, color = color_map[0], label = "HanGu-isolated, BS_SSC = 600")
ax0.plot(x, opt_bw_ratio, marker = '<',           markersize = MARKER_SIZE, linewidth=LINE_WIDTH, color = color_map[1], label = "HanGu-isolated, BS_SSC = 300")
ax0.plot(x, ideal_isolation, marker = '^',        markersize = MARKER_SIZE, linewidth=LINE_WIDTH, color = color_map[2], label = "Ideal isolation")
ax0.set_xlabel('BS tenant-1 message size (bytes)', fontsize=FONT_SIZE)
ax0.set_ylabel('Bandwidth ratio: \n tenant-1 / tenant-0', fontsize=FONT_SIZE)
ax0.set_xticks(x)
ax0.set_xticklabels(bs1_msg_size_list, fontsize=FONT_SIZE)
ax0.tick_params(axis='y', labelsize =FONT_SIZE)
ax0.legend(fontsize=FONT_SIZE, frameon=False)
# plt.title("Ratio of achievable bandwidth, message size of BS Flow-0 is 128KB", fontsize=FONT_SIZE)
fig0.tight_layout()

plt.savefig("./res_out/figures/analysis_bw_ratio_change_ssc_bs0_{}_4k_ssc_{}.png".\
            format(BS0_MSG_SIZE_4K, SSC))
plt.savefig("./res_out/figures/analysis_bw_ratio_change_ssc_bs0_{}_4k_ssc_{}.pdf".\
            format(BS0_MSG_SIZE_4K, SSC))

fig1, ax1 = plt.subplots(figsize=(10, 4))
# ax1.plot(x, base_bs0_bw, marker = '<', markersize = 10, label = "Base BS Flow-0", linewidth=3, color = "#0072BD")
# ax1.plot(x, opt_bs0_bw, marker = '>', markersize = 10, label = "Opt BS Flow-0", linewidth=3,   color = "#0072BD")
ax1.plot(x, base_bs0_bw, marker = '<', markersize = 10, label = "Base BS Flow-0", linewidth=3, color = color_map[0])
ax1.plot(x, opt_bs0_bw, marker = '>', markersize = 10, label = "Opt BS Flow-0", linewidth=3,   color = color_map[0])
ax1.set_xlabel('BS Flow-1 Message Size(Byte)', fontsize=FONT_SIZE)
# ax1.set_ylabel('BS Flow-0 \n Bandwidth(Gbps)', fontsize=FONT_SIZE, color = "#0072BD")
ax1.set_ylabel('BS Flow-0 \n Bandwidth(Gbps)', fontsize=FONT_SIZE, color = color_map[0])
ax1.set_xticks(x)
ax1.set_xticklabels(bs1_msg_size_list, fontsize=FONT_SIZE)
ax1.tick_params(axis='y', labelsize =FONT_SIZE)
ax1.set_ylim(0,100)

ax1_t = ax1.twinx()
# ax1_t.plot(x, base_bs1_bw, marker = '^', markersize = 10, label = 'Base BS Flow-1', linewidth=3, color = '#D95319')
# ax1_t.plot(x, opt_bs1_bw, marker = 'v', markersize = 10, label = 'Opt BS Flow-1', linewidth=3, color = '#D95319')
ax1_t.plot(x, base_bs1_bw, marker = '^', markersize = 10, label = 'Base BS Flow-1', linewidth=3, color = color_map[1])
ax1_t.plot(x, opt_bs1_bw, marker = 'v', markersize = 10, label = 'Opt BS Flow-1', linewidth=3, color = color_map[1])
# ax1_t.set_ylabel('BS Flow-1 \n Bandwidth(Gbps)', fontsize=FONT_SIZE, color = '#D95319')
ax1_t.set_ylabel('BS Flow-1 \n Bandwidth(Gbps)', fontsize=FONT_SIZE, color = color_map[1])
ax1_t.tick_params(axis='y', labelsize =FONT_SIZE)
ax1_t.set_ylim(0,100)

box1 = ax1.get_position()
# move ax1 up for 10%
ax1.set_position([box1.x0, box1.y0 - box1.height * 0.1, 
                  box1.width, box1.height * 0.9])
# put legend below ax1
fig1.legend(fontsize=FONT_SIZE, frameon=False, loc="center", ncol=2, 
            bbox_to_anchor=(0.5, 1.05), fancybox=True, shadow=True)
# plt.title("Achievable bandwidth, message size of BS Flow-0 is 128KB", fontsize=FONT_SIZE)

fig1.subplots_adjust(top=0.9)
fig1.tight_layout()
plt.savefig("./res_out/figures/bw_bs0_{}_4k_ssc_{}.png".format(BS0_MSG_SIZE_4K, SSC))
plt.savefig("./res_out/figures/bw_bs0_{}_4k_ssc_{}.pdf".format(BS0_MSG_SIZE_4K, SSC))
