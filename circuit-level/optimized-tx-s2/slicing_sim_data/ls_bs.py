# -*- coding: utf-8 -*-

import matplotlib.pyplot as plt
import numpy as np
from palettable.cartocolors.qualitative import Bold_10
color_map = Bold_10.hex_colors

labels = ['4K', '8K', '16K', '32K', '64K', '128K', '256K', '512K', '1M']
FONT_SIZE = 16
LINE_WIDTH = 2
MARKER_SIZE = 10

ls_wont_p99_avg = 170
ls_with_bs_p99_avg = np.array([3440, 6000, 11120, 21340, 41840, 82800, 164720, 329560, 656240])
ls_with_bs_p99_opt = np.array([260, 580, 1220, 2500, 5060, 10180, 20420, 40900, 81860])
ls_with_bs_p99_opt_s2 = np.array([270, 270, 270, 270, 270, 270, 270, 270, 270])
ls_with_bs_p99_inc = ls_with_bs_p99_avg / ls_wont_p99_avg
ls_with_bs_p99_opt_inc = ls_with_bs_p99_opt / ls_wont_p99_avg
ls_wont_p99_avg_s2 = 160
ls_with_bs_p99_opt_s2_inc = ls_with_bs_p99_opt_s2 / ls_wont_p99_avg_s2

x = np.arange(len(labels))  # the label locations
# plot ls with bs
fig0, ax0 = plt.subplots(figsize=(10, 4))

# ax0.plot(x, ls_with_bs_p99_inc, marker = '.', markersize = MARKER_SIZE, label = "baseline", color = "#f08c55", linewidth=LINE_WIDTH)
# ax0.plot(x, ls_with_bs_p99_opt_s2_inc, marker = '*', markersize = MARKER_SIZE, label = "optimized-v1", color = "#6ec8c8", linewidth=LINE_WIDTH)

ax0.plot(x, ls_with_bs_p99_inc, marker = '.', markersize = MARKER_SIZE, label = "baseline", color = color_map[0], linewidth=LINE_WIDTH)
ax0.plot(x, ls_with_bs_p99_opt_s2_inc, marker = '*', markersize = MARKER_SIZE, label = "optimized-v1", color = color_map[1], linewidth=LINE_WIDTH)
# Add some text for labels, title and custom x-axis tick labels, etc.
ax0.set_xlabel('BS tenant message size (bytes)', fontsize=FONT_SIZE)
ax0.set_ylabel('LS tenant P99 latency \n increase ratio', fontsize=FONT_SIZE)
ax0.set_xticks(x)
ax0.set_xticklabels(labels, fontsize=FONT_SIZE)
ax0.tick_params(axis='y', labelsize =FONT_SIZE)
# plt.yscale("log")
fig0.legend(fontsize=FONT_SIZE, frameon=False, loc="center")

fig0.tight_layout()
# plt.savefig("ls_with_bs.svg")
plt.savefig("ls_with_bs.pdf")
plt.savefig("ls_with_bs.png")
plt.show()