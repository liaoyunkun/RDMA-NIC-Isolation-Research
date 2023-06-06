# -*- coding: utf-8 -*-

import matplotlib.pyplot as plt
import numpy as np
from matplotlib.ticker import MaxNLocator
from palettable.cartocolors.qualitative import Bold_10
color_map = Bold_10.hex_colors

labels = ['1', '2', '4', '8']
FONT_SIZE = 10
LINE_WIDTH = 2
MARKER_SIZE = 10
ls_lat = np.array([270, 270, 270, 270])
ls_lat = ls_lat / 10

x = np.arange(len(labels))  # the label locations
# plot ls with bs
fig0, ax0 = plt.subplots(figsize=(10, 3))

# ax0.plot(x, ls_lat, marker = '.', markersize = MARKER_SIZE, label = "optimized-v1, BS message size = 1MB", color = "#F08C55", linewidth=LINE_WIDTH)
ax0.plot(x, ls_lat, marker = '.', markersize = MARKER_SIZE, label = "optimized-v1, BS message size = 1MB", color = color_map[0], linewidth=LINE_WIDTH)
# Add some text for labels, title and custom x-axis tick labels, etc.
ax0.set_xlabel('Number of BS tenants', fontsize=FONT_SIZE)
ax0.set_ylabel('LS tenant P99 latency \n(Clock cycles)', fontsize=FONT_SIZE)
ax0.set_xticks(x)
ax0.set_xticklabels(labels, fontsize=FONT_SIZE)
ax0.tick_params(axis='y', labelsize =FONT_SIZE)
ax0.yaxis.set_major_locator(MaxNLocator(integer=True))
# plt.yscale("log")
fig0.legend(fontsize=FONT_SIZE, frameon=False, loc="center")

fig0.tight_layout()
# plt.savefig("ls_with_bs.svg")
plt.savefig("ls_bs_mbs.pdf")
plt.savefig("ls_bs_mbs.png")
plt.show()