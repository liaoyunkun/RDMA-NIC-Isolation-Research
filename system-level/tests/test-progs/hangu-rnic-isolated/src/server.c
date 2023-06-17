#include "librdma.h"

int svr_update_qps(struct rdma_resc *resc) {

    for (int i = 0; i < resc->num_qp * resc->num_rem; ++i) {
        /* Modify Local QP */
        struct ibv_qp *qp = resc->qp[i];
        qp->ctx = resc->ctx;
        qp->flag = 0;
        qp->type = QP_TYPE_RC;
        qp->cq = resc->cq[i % TEST_CQ_NUM];
        qp->snd_wqe_offset = 0;
        qp->rcv_wqe_offset = 0;
        qp->lsubnet.llid = resc->ctx->lid;
        qp->dest_qpn = (cpu_id << RESC_LIM_LOG) + (i / resc->num_rem) + 1;
        qp->snd_psn = 0;
        qp->ack_psn = 0;
        qp->exp_psn = 0;
        qp->dsubnet.dlid = (i % resc->num_rem) + resc->ctx->lid + 1;
        RDMA_PRINT(Server, "svr_update_qps: start modify_qp, dlid %d, src_qp 0x%x, dst_qp 0x%x, cqn 0x%x, i %d\n", 
                qp->dsubnet.dlid, qp->qp_num, qp->dest_qpn, qp->cq->cq_num, i);
        // ibv_modify_qp(resc->ctx, qp);
    }
    ibv_modify_batch_qp(resc->ctx, resc->qp[0], resc->num_qp * resc->num_rem);

    return 0;
}

int svr_update_info(struct rdma_resc *resc) {
    RDMA_PRINT(Server, "Start svr_update_info\n");
    int sum = 0, num;
    struct rdma_cr *cr_info;
    uint16_t *dest_info = (uint16_t *)malloc(sizeof(uint16_t) * resc->num_rem);

    while (sum < resc->num_rem) {
        cr_info = rdma_listen(resc, &num); /* listen connection request from client (QP0) */
        if (num == 0) { /* no cr_info is acquired */
            continue;
        }
        RDMA_PRINT(Server, "svr_update_info: rdma_listen end, Polled %d CR data\n", num);
        
        for (int i = 0; i < num; ++i) {

            /* get remote addr information */
            resc->rinfo[sum].dlid  = cr_info[i].src_lid;
            resc->rinfo[sum].raddr = cr_info[i].raddr;
            resc->rinfo[sum].rkey  = cr_info[i].rkey;
            ++sum;

            /* Generate Connect Request to respond client */
            cr_info[i].flag = CR_TYPE_ACK;
            cr_info[i].raddr = (uintptr_t)resc->mr[0]->addr;
            cr_info[i].rkey  = resc->mr[0]->lkey;
            dest_info[i] = cr_info[i].src_lid;

            RDMA_PRINT(Server, "svr_update_info: sum %d resc_num_rem %d, cr_info[i].raddr %ld cr_info[i].rkey %d dest_info[i] %d\n", 
                    sum, resc->num_rem, cr_info[i].raddr, cr_info[i].rkey, dest_info[i]);
        }
        RDMA_PRINT(Server, "svr_update_info: start rdma_connect, sum %d\n", sum);
        rdma_connect(resc, cr_info, dest_info, num); /* post connection request to client (QP0) */
        free(cr_info);
    }
    free(dest_info);

    /* modify qp in server side */
    svr_update_qps(resc);

    return 0;
}

int svr_connect_qps(struct rdma_resc *resc) {
    RDMA_PRINT(Server, "Start svr_connect_qps\n");
    int sum = 0, num, rem_sum = 0;
    struct rdma_cr *cr_info;
    uint16_t *dest_info = (uint16_t *)malloc(sizeof(uint16_t) * SND_WR_MAX * resc->num_rem);

    while (sum < resc->num_qp * resc->num_rem) {
        cr_info = rdma_listen(resc, &num); /* listen connection request from client (QP0) */
        if (num == 0) {
            continue;
        }
        RDMA_PRINT(Server, "svr_connect_qps: rdma_listen end, Polled %d CR data\n", num);
        
        for (int i = 0; i < num; ++i) {

            RDMA_PRINT(Server, "svr_connect_qps: rem_sum %d resc_num_rem %d\n", rem_sum, resc->num_rem);

            /* get remote addr information */
            struct rem_info *rinfo_ptr = NULL;
            for (int j = 0; j < resc->num_rem; ++j) {
                if (resc->rinfo[j].dlid == cr_info[i].src_lid) {
                    rinfo_ptr = &(resc->rinfo[j]);
                    break;
                }
            }
            if (rinfo_ptr == NULL) {
                // RDMA_PRINT(Server, "pointer is NULL rem_ptr 0x%lx\n", (uintptr_t)rinfo_ptr);
                resc->rinfo[rem_sum].dlid  = cr_info[i].src_lid;
                resc->rinfo[rem_sum].raddr = cr_info[i].raddr;
                resc->rinfo[rem_sum].rkey  = cr_info[i].rkey;
                rinfo_ptr = &(resc->rinfo[rem_sum]);
                ++rem_sum;
            }
            
            RDMA_PRINT(Server, "svr_connect_qps: start modify_qp, total_sum %d, qp_sum %d, cq sum %d, start_off %d\n", 
                    sum, rinfo_ptr->sum, rinfo_ptr->sum % TEST_CQ_NUM, rinfo_ptr->start_off);
            /* Modify Local QP */
            struct ibv_qp *qp;
            qp = resc->qp[rinfo_ptr->sum + rinfo_ptr->start_off];
            qp->ctx = resc->ctx;
            qp->flag = 0;
            qp->type = cr_info[i].qp_type;
            qp->cq = resc->cq[sum % TEST_CQ_NUM];
            qp->snd_wqe_offset = 0;
            qp->rcv_wqe_offset = 0;
            qp->lsubnet.llid = resc->ctx->lid;
            qp->dest_qpn = cr_info[i].src_qpn;
            qp->snd_psn = 0;
            qp->ack_psn = qp->snd_psn;
            qp->exp_psn = cr_info[i].snd_psn;
            qp->dsubnet.dlid = cr_info[i].src_lid;
            RDMA_PRINT(Server, "svr_connect_qps: start modify_qp, dlid %d, src_qp %d, dst_qp %d, cqn %d\n", 
                    qp->dsubnet.dlid, qp->qp_num, qp->dest_qpn, qp->cq->cq_num);
            ibv_modify_qp(resc->ctx, qp);

            /* Generate Connect Request to respond client */
            cr_info[i].dst_qpn = qp->qp_num;
            cr_info[i].snd_psn = qp->snd_psn;
            cr_info[i].flag = CR_TYPE_ACK;
            cr_info[i].raddr = (uintptr_t)resc->mr[0]->addr;
            cr_info[i].rkey  = resc->mr[0]->lkey;
            dest_info[i] = cr_info[i].src_lid;
            RDMA_PRINT(Server, "svr_connect_qps: dest 0x%x cr_info dlid 0x%x dst_qpn %d src_qpn %d\n", 
                    dest_info[i], cr_info[i].src_lid, cr_info[i].dst_qpn, cr_info[i].src_qpn);

            ++rinfo_ptr->sum;
            ++sum;
        }
        RDMA_PRINT(Server, "svr_connect_qps start rdma_connect, sum %d\n", sum);
        rdma_connect(resc, cr_info, dest_info, num); /* post connection request to client (QP0) */
        free(cr_info);
    }

    return 0;
}

int svr_fill_mr (struct ibv_mr *mr, uint32_t offset) {

#define TRANS_WRDMA_DATA "Hello World!  Hello RDMA Write! Hello World!  Hello RDMA Write!"
#define TRANS_RRDMA_DATA "Hello World!  Hello RDMA Read ! Hello World!  Hello RDMA Read !"
    
    char *string = (char *)(mr->addr + offset);
    memcpy(string, TRANS_WRDMA_DATA, sizeof(TRANS_WRDMA_DATA));
    
    return 0;
}

int svr_post_send (struct rdma_resc *resc, struct ibv_qp *qp, int wr_num, uint32_t offset, uint8_t op_mode) {

    // RDMA_PRINT(Server, "enter svr_post_send %d\n", wr_num);
    struct ibv_wqe wqe[TEST_WR_NUM];
    struct ibv_mr *local_mr = (resc->mr)[0];

    // RDMA_PRINT(Server, "wqe addr 0x%lx, local_mr addr 0x%lx\n", (uint64_t)wqe, (uint64_t)local_mr);
    // RDMA_PRINT(Server, "start svr_post_send qp_num %d, dst_qpn %d, mr addr 0x%lx, wr_num %d, off %d\n", 
    //         qp->qp_num, qp->dest_qpn, (uint64_t)(local_mr->addr), wr_num, offset);

    // RDMA_PRINT(Server, "svr_post_send: raddr 0x%lx, rkey 0x%x, dlid 0x%x\n", 
    //         resc->rinfo->raddr, resc->rinfo->rkey, resc->rinfo->dlid);
    
    if (op_mode == OPMODE_RDMA_WRITE) {

        for (int i = 0; i < wr_num; ++i) {
            // wqe[i].length = sizeof(TRANS_WRDMA_DATA);
            if (LS_BS == 1) {
                if (resc->cpu_id == LS_CPU_ID) {
                    wqe[i].length = MSG_SIZE_LS;
                } else if (resc->cpu_id == BS_CPU_ID) {
                    wqe[i].length = MSG_SIZE_BS;
                }
            } else {
                // BS-BS
                if (resc->cpu_id == BS0_CPU_ID) {
                    wqe[i].length = BS0_MSG_SIZE;
                    // printf("post bs0 length %d\n", wqe[i].length);
                } else if (resc->cpu_id == BS1_CPU_ID) {
                    wqe[i].length = BS1_MSG_SIZE;
                    // printf("post bs1 length %d\n", wqe[i].length);
                }
            }
            
            wqe[i].mr = local_mr;
            wqe[i].offset = offset;
            
            /* Add RDMA Write element */
            wqe[i].trans_type = IBV_TYPE_RDMA_WRITE;
            wqe[i].flag       = (i == wr_num - 1) ? WR_FLAG_SIGNALED : 0;
            wqe[i].rdma.raddr = resc->rinfo->raddr + (sizeof(TRANS_WRDMA_DATA) - 1) * i + offset;
            wqe[i].rdma.rkey  = resc->rinfo->rkey;
        }
        
    } else if (op_mode == OPMODE_RDMA_READ) {
        
        for (int i = 0; i < wr_num; ++i) {
            wqe[i].length = sizeof(TRANS_RRDMA_DATA);
            wqe[i].mr = local_mr;
            wqe[i].offset = (sizeof(TRANS_RRDMA_DATA) - 1) * i + offset;

            /* Add RDMA Read element */
            wqe[i].trans_type = IBV_TYPE_RDMA_READ;
            wqe[i].flag       = (i == wr_num - 1) ? WR_FLAG_SIGNALED : 0;
            wqe[i].rdma.raddr = resc->rinfo->raddr + offset;
            wqe[i].rdma.rkey  = resc->rinfo->rkey;
        }
        
    }
    
    ibv_post_send(resc->ctx, wqe, qp, wr_num);

    return 0;
}

static void usage(const char *argv0) {
    printf("Usage:\n");
    printf("  %s            start a client and build connection\n", argv0);
    printf("  %s <host>     connect to server at <host>\n", argv0);
    printf("\n");
    printf("Options:\n");
    printf("  -s, --svr-lid=<lid>               server's lid (default 0x0)\n");
    printf("  -t, --num-client=<num_client>     number of clients (default 1)\n");
    printf("  -c, --cpu-id=<cpu_id>             id of the cpu (default 0)\n");
    printf("  -m, --op-mode=<op_mode>           opcode mode (default 0, which is RDMA Write)\n");
}

double ls_flow(struct rdma_resc *resc, int num_qp, uint8_t op_mode) {
    // uint64_t start_time, end_time, con_time = 0;
    uint64_t start_time[ITER_LS];
    uint64_t end_time[ITER_LS];
    struct cpl_desc **desc = resc->desc;
    uint8_t polling;
    uint8_t ibv_type[] = {IBV_TYPE_RDMA_WRITE, IBV_TYPE_RDMA_READ};
    // printf("ls qpn: %08x\n", resc->qp[0]->qp_num);
    for (int i = 0; i < ITER_LS; i++) {
        struct ibv_qp *qp = resc->qp[0];
        start_time[i] = get_time(resc->ctx);
        svr_post_send(resc, resc->qp[0], 1, 0, op_mode);
        // printf("ls post %d\n", i);
        polling = 1;
        while (polling) {
            int res = ibv_poll_cpl(qp->cq, desc, MAX_CPL_NUM);
            for (int j  = 0; j < res; ++j) {
                // printf("ls poll %d\n", i);
                if (desc[j]->trans_type == ibv_type[op_mode]) {
                    polling = 0;
                    end_time[i] = get_time(resc->ctx);
                    break;
                }
            }
        }
    }
    for (int i = 0; i < ITER_LS; i++) {
        printf("LS: %.2lf ns\n", i, ((end_time[i] - start_time[i]) / 1000.0));
    }    
    return 0;
}


double bs_flow(struct rdma_resc *resc, int num_qp, uint8_t op_mode) {
    // uint64_t start_time, end_time, con_time = 0;
    uint64_t start_time[ITER_BS];
    uint64_t end_time[ITER_BS];
    struct cpl_desc **desc = resc->desc;
    uint8_t polling;
    uint8_t ibv_type[] = {IBV_TYPE_RDMA_WRITE, IBV_TYPE_RDMA_READ};
    // printf("bs qpn: %08x\n", resc->qp[0]->qp_num);
    for (int i = 0; i < ITER_BS; i++) {
        struct ibv_qp *qp = resc->qp[0];
        start_time[i] = get_time(resc->ctx);
        svr_post_send(resc, resc->qp[0], 1, 0, op_mode);
        // printf("bs post %d\n", i);
        polling = 1;
        while (polling) {
            int res = ibv_poll_cpl(qp->cq, desc, MAX_CPL_NUM);
            for (int j  = 0; j < res; ++j) {
                // printf("bs poll %d\n", i);
                if (desc[j]->trans_type == ibv_type[op_mode]) {
                    polling = 0;
                    end_time[i] = get_time(resc->ctx);
                    break;
                }
            }
        }
    }
    for (int i = 0; i < ITER_BS; i++) {
        printf("BS: %.2lf ns\n", i, ((end_time[i] - start_time[i]) / 1000.0));
    }    
    return 0;
}

double bs_flow_0(struct rdma_resc *resc, uint8_t op_mode, uint32_t offset, 
    uint64_t *start_time, uint64_t *end_time, uint64_t *con_time, uint64_t *snd_cnt) {
    uint8_t ibv_type[] = {IBV_TYPE_RDMA_WRITE, IBV_TYPE_RDMA_READ};   
    *start_time = get_time(resc->ctx);
    // post initial batch for bandwidth
    svr_post_send(resc, resc->qp[0], BS_INIT_BATCH, offset, op_mode);
    /* polling for completion */
    struct cpl_desc **desc = resc->desc;
    struct ibv_qp *qp = resc->qp[0];
    uint8_t polling;
    do { 
        int res = ibv_poll_cpl(qp->cq, desc, MAX_CPL_NUM);
        if (res) {
            printf("poll %d cqes\n", res);
            for (int j  = 0; j < res; ++j) {
                if (desc[j]->trans_type == ibv_type[op_mode]) {
                    *snd_cnt +=  1;
                    svr_post_send(resc, resc->qp[0], 1, offset, op_mode); 
                }
            }
        }
        *end_time = get_time(resc->ctx);
        *con_time = *end_time - *start_time;
        // printf("BS-0 CON_TIME %d ns\n", *con_time/1000);
    } while ((*con_time < 100UL * MS));

    return (*snd_cnt * 1000000.0) / *con_time; /* message rate, Mops */
}

double bs_flow_1(struct rdma_resc *resc, uint8_t op_mode, uint32_t offset, 
    uint64_t *start_time, uint64_t *end_time, uint64_t *con_time, uint64_t *snd_cnt) {
    uint8_t ibv_type[] = {IBV_TYPE_RDMA_WRITE, IBV_TYPE_RDMA_READ};
    int num_qp = resc->num_qp;
    int num_cq = resc->num_cq;    
    *start_time = get_time(resc->ctx);
    // post initial batch for bandwidth
    svr_post_send(resc, resc->qp[0], BS_INIT_BATCH, offset, op_mode);
    /* polling for completion */
    struct cpl_desc **desc = resc->desc;
    struct ibv_qp *qp = resc->qp[0];
    uint8_t polling;
    do { 
        int res = ibv_poll_cpl(qp->cq, desc, MAX_CPL_NUM);
        if (res) {
            printf("poll %d cqes\n", res);
            for (int j  = 0; j < res; ++j) {
                if (desc[j]->trans_type == ibv_type[op_mode]) {
                    *snd_cnt +=  1;
                    svr_post_send(resc, resc->qp[0], 1, offset, op_mode); 
                }
            }
        }
        *end_time = get_time(resc->ctx);
        *con_time = *end_time - *start_time;
        // printf("BS-1 CON_TIME %d ns\n", *con_time/1000);
    } while ((*con_time < 100UL * MS));

    return (*snd_cnt * 1000000.0) / *con_time; /* message rate, Mops */
}

int main (int argc, char **argv) {

    int num_mr, num_cq, num_qp;
    uint64_t snd_cnt = 0;
    uint16_t svr_lid = 0;
    uint8_t  op_mode = OPMODE_RDMA_WRITE; /* 0: RDMA Write; 1: RDMA Read */

    num_client = 1;
    cpu_id     = 0;
    sprintf(id_name, "%d", svr_lid);

    uint64_t start_time, end_time, con_time;
    uint64_t bs0_start_time, bs0_end_time, bs0_con_time, bs0_snd_cnt;
    uint64_t bs1_start_time, bs1_end_time, bs1_con_time, bs1_snd_cnt;
    double latency, msg_rate, bandwidth;
    double bs0_msg_rate, bs0_bandwidth;
    double bs1_msg_rate, bs1_bandwidth;
    uint32_t offset = 0;

    while (1) {
        int c;

        static struct option long_options[] = {
            { .name = "server-lid",   .has_arg = 1, .val = 's' },
            { .name = "num-client",   .has_arg = 1, .val = 't' },
            { .name = "cpu-id"    ,   .has_arg = 1, .val = 'c' },
            { .name = "op-mode"   ,   .has_arg = 1, .val = 'm' },
            { 0 }
        };

        c = getopt_long(argc, argv, "s:t:c:m:", long_options, NULL);
        if (c == -1)
            break;

        switch (c) {
          case 's':
            if (!sscanf(optarg, "%hd", &svr_lid)) {
                RDMA_PRINT(Server, "Error in svr_lid parser. Exit.\n");
                exit(-1);
            }
            break;

          case 't':
            if (!sscanf(optarg, "%d", &num_client)) {
                RDMA_PRINT(Server, "Error in num client parser. Exit.\n");
                exit(-1);
            }
            break;
          case 'c':
            if (!sscanf(optarg, "%hhd", &cpu_id)) {
                RDMA_PRINT(Server, "Error in cpu id parser. Exit.\n");
                exit(-1);
            }
            break;
          case 'm':
            if (!sscanf(optarg, "%hhd", &op_mode)) {
                RDMA_PRINT(Server, "Error in op mode parser. Exit.\n");
                exit(-1);
            }
            break;

          default:
            usage(argv[0]);
            return 1;
        }
    }

    sprintf(id_name, "%d", svr_lid);
    RDMA_PRINT(Server, "llid is %hd\n", svr_lid);
    RDMA_PRINT(Server, "num_client %d\n", num_client);

    num_mr = 1;
    num_cq = TEST_CQ_NUM;
    num_qp = TEST_QP_NUM;
    RDMA_PRINT(Server, "num_qp %d num_cq %d\n", num_qp, num_cq);
    struct rdma_resc *resc = rdma_resc_init(num_mr, num_cq, num_qp, svr_lid, num_client);
    resc->cpu_id = cpu_id;

    /* Connect QPs to client's QP */
    // svr_connect_qps(resc);
    svr_update_info(resc);
    RDMA_PRINT(Server, "svr_connect_qps end\n");
    /* sync to make sure that we could get start */
    rdma_recv_sync(resc);
    /* Inform other CPUs that we can start */
    cpu_sync(resc->ctx);
    if (LS_BS == 1) {
        if (cpu_id == LS_CPU_ID) {
            RDMA_PRINT(Server, "LS start!\n");
            latency = ls_flow(resc, num_qp, op_mode);
            RDMA_PRINT(Server, "LS end!\n");
        } else if (cpu_id == BS_CPU_ID) {
            RDMA_PRINT(Server, "BS start!\n");
            latency = bs_flow(resc, num_qp, op_mode);
            RDMA_PRINT(Server, "BS end!\n");
        }    
    } else {
        if (cpu_id == BS0_CPU_ID) {
            RDMA_PRINT(Server, "BS-0 start!\n");
            bs0_snd_cnt = 0;
            bs0_msg_rate = bs_flow_0(resc, op_mode, offset, &bs0_start_time, &bs0_end_time, &bs0_con_time, &bs0_snd_cnt);
            RDMA_PRINT(Server, "BS-0 end!\n");
            printf("BS_0 con_time %d ns, snd_cnt %d\n", bs0_con_time / 1000, bs0_snd_cnt);
            printf("BS_0 Bandwidth %lf\n", bs0_msg_rate * BS0_MSG_SIZE * 8);
        } else if (cpu_id == BS1_CPU_ID) {
            RDMA_PRINT(Server, "BS-1 start!\n");
            bs1_snd_cnt = 0;
            bs1_msg_rate = bs_flow_1(resc, op_mode, offset, &bs1_start_time, &bs1_end_time, &bs1_con_time, &bs1_snd_cnt);
            RDMA_PRINT(Server, "BS-1 end!\n");
            printf("BS_1 con_time %d ns, snd_cnt %d\n", bs1_con_time / 1000, bs1_snd_cnt);
            printf("BS_1 Bandwidth %lf\n", bs1_msg_rate * BS1_MSG_SIZE * 8);
        }
    }
    /* Inform Client that Transmission has completed */
    rdma_recv_sync(resc);
    /* Inform other CPUs that we can exit */
    cpu_sync(resc->ctx);
    /* close the fd */
    RDMA_PRINT(Server, "fd : %d\n", ((struct hghca_context*)resc->ctx->dvr)->fd);
    close(((struct hghca_context*)resc->ctx->dvr)->fd);
    
    return 0;
    
}