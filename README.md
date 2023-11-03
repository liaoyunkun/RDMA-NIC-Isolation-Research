# RDMA-NIC-Isolation-Research

This repo contains source code for the published paper related to RDMA NIC architecture optimizations for performance isolation [1]. The source code includes circuit-level and system-level evaluations. The circuit-level evaluation is implemented in Verilog and Systemverilog. Thanks Alex Forencich for his verilog-axi implementations [2]. The system-level evaluation is implemented in GEM-5 simulator based on HanGu simulator [3, 4]. 

[1] Yunkun Liao, Jingya Wu, Wenyan Lu, Xiaowei Li, and Guihai Yan. 2023. Optimize the TX Architecture of RDMA NIC for Performance Isolation in the Cloud Environment. In Proceedings of the Great Lakes Symposium on VLSI 2023 (GLSVLSI '23). Association for Computing Machinery, New York, NY, USA, 29–35. https://doi.org/10.1145/3583781.3590276

[3] Alex Forencich, "verilog-axi", https://github.com/alexforencich/verilog-axi 

[3] Kang, Ning, Zhan Wang, F. Yang, Xiaoxiao Ma, Zhenlong Ma, Guojun Yuan and Guangming Tan. “csRNA: Connection-Scalable RDMA NIC Architecture in Datacenter Environment.” 2022 IEEE 40th International Conference on Computer Design (ICCD) (2022): 398-406.

[4] NCSG Group, "csRNA", https://github.com/ncsg-group/csRNA

