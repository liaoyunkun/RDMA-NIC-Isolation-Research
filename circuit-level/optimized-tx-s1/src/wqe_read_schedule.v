
`default_nettype none
`timescale 1ps/1ps

module wqe_read_schedule
    #(
        parameter	MAX_QP          = 32,	        
        parameter	QP_PTR_WIDTH    = 5	
    )
    (
    input  wire 				      clk, 
    input  wire 				      rst_n, 
    input  wire 				      i_arbit, 
    input  wire 				      i_enable, 
    input  wire [MAX_QP -1:0]         i_active,	
    output wire 			          o_arbit_val, 
    output wire [QP_PTR_WIDTH -1 :0]  o_qp_idx,
    output wire [MAX_QP -1:0]         o_qp_idx_one_hot
    );

    wire [MAX_QP-1:0]          i_elmnt_unavail;    // Element is unavailable for arbitration
    // Common Declartion
    reg  [MAX_QP -1:0] 	       qp_avail;           // one hot representation of all qp available
    wire [MAX_QP -1:0] 	       qp_avail_combo;     // one hot representation of all qp available
    reg 					   qp_avail_ff;        // regsiter version used for arb genration to match pipeline
    reg 					   qp_avail_2ff;       // regsiter version used for arb genration to match pipeline
    reg  [QP_PTR_WIDTH -1 :0]  sel_qp;             // arabitrated qp
    reg  [QP_PTR_WIDTH -1 :0]  sel_qp_next;        // next arbitrated qp
    reg 					   initial_condition;  // represent state after reset or when current selected qp ack and no wqe ub any other qp
    reg  [MAX_QP -1:0] 	       elmnt_index;        // one hot representation of selected qp available


   //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   // initial condition and arbitration done generation can be optimized if handshake mechinsum get updated or optimised
   // ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    reg 					   arb_done;                                // arbitration done; if any qp is available process will be done in 1 clk cycle 
    genvar 				       gi;
    integer 				   i;

    reg  [MAX_QP/8 -1:0] 	   qp_grp_valid;                            // set of 8 qp has any one or more queue available
    wire [7:0] 				   qp_avail_2d [MAX_QP/8 -1:0];             // 2d stack of one hot representation of all qp available
    wire [7:0] 				   qp_avail_2d_combo [MAX_QP/8 -1:0];       // 2d stack of one hot representation of all qp available
    reg  [MAX_QP/8 -1:0] 	   qp_grp_valid_shifted;                    // list of qp grp valid after circulate shifti
    reg  [QP_PTR_WIDTH -1-3 :0]next_qp_grp_base_addr_proc;              // to be added in to current arbitrated qp index
    reg  [QP_PTR_WIDTH -1-3 :0]next_qp_grp_base_addr;                   // to be added in to current arbitrated qp index
    reg  [7:0] 				   qp_avail_of_next_qp_grp_shifted;         // queue valid for next qp group which is valid
    wire [7:0] 				   qp_avail_of_curr_qp_grp;                 // queue valid for next qp group which is valid
    reg  [2:0] 				   nxt_qp_avail_of_curr_qp_grp ;            // qp_available in current_qp_grp : current 1 qp served at lowest priority
    reg  [2:0] 				   next_qp_grp_offset_addr;                 // queue offset addr valid for next qp which is available of next qp group 
    //else qp is less than 8 or equal
    wire 				       arb_done_flush;                          // to flush arbitrated value which become unavail in between process
    reg  [7:0] 				   qp_avail_of_curr_qp_grp_shifted;
    reg  [2:0] 				   qp_avail_of_qp_grp [MAX_QP/8-1:0];       // offset addresses of all qp grp
    wire [2:0] 				   qp_avail_of_next_qp_grp;                 // selected next qp offset address

    wire 				       qp_seltected_pulse;                      // qp index available as ouput
    wire 				       qp_next_base_addr_proc_en;
    reg 					   qp_next_base_addr_proc_en_ff;
    wire                       arbitrate;
    wire                       dummy_i_arbit;
    reg                        dummy_i_arbit_ff;
    reg  [MAX_QP -1:0] 	       qp_avail_shifted;                        // Shifting all qp as per current qp value

    assign i_elmnt_unavail = ~i_active;
    // o_elemnt_index : output ; arbitrated qp
    assign o_qp_idx = sel_qp;

    // o_element_index_one_hot : arbitrated qp in one hot 
    always @(*)
        begin
            for (i= 0; i<MAX_QP; i=i+1)
                begin
                    if (sel_qp == i && i_enable) 
                        elmnt_index[i] <= 1'b1;
                    else
                        elmnt_index[i] <= 1'b0;
                end
        end
   assign o_qp_idx_one_hot = elmnt_index;

    // Qp avaialble for arbitration
    always @(posedge clk or negedge rst_n)
        begin
            if (~rst_n)		
                qp_avail <= {MAX_QP{1'b0}};
            else 
            qp_avail <= qp_avail_combo;
        end

    assign qp_avail_combo = ~i_elmnt_unavail;
   
  
    // register qp availble for arbitration
    always @(posedge clk or negedge rst_n)
        begin
            if (~rst_n)		
                qp_avail_ff <= {MAX_QP{1'b0}};
            else 
            qp_avail_ff <= |qp_avail;
        end


    // Priority function : select the first one occurenc in input array "in_val
    // from bit 1:7; keeping first but on higest priority and 7 bit on second
    // lowest priority and 0th bit has lowest priority among all


    // to circular shift all configured qp valid signal
    function [MAX_QP -1:0] circ_shift_ttl_arb;
        input [MAX_QP -1:0]         shift_val;
        input [ QP_PTR_WIDTH -1:0] 	shifted_with;
        reg   [MAX_QP -1:0] 	    shifted_val;
        integer 				    k;
            begin
                shifted_val = shift_val; 
                for (k = 1; k < MAX_QP ; k=k+1)
                    if (shifted_with >= k)
                        begin	
                            shifted_val = {shifted_val[0],shifted_val[MAX_QP -1:1]}; // circular left shift by 1
                        end	
                circ_shift_ttl_arb = shifted_val;
            end	
    endfunction

    // to priortise among all configured qp valid signal ; afer circular shift
    function [QP_PTR_WIDTH :0] priority_ttl_arb;
        input [MAX_QP-1 :0] in_val;
        integer 			       j;
        begin
            priority_ttl_arb = {QP_PTR_WIDTH {1'b0}};
            for (j = 1; j < MAX_QP ; j=j+1)
                if (in_val[j])
                    begin	
                        priority_ttl_arb = j; // overide privious index
                    end
        end
    endfunction

    //output arbitration done
    //assign o_arbit_val = arb_done && (!arbitrate) && (!arb_done_flush);
    assign arbitrate = i_arbit || dummy_i_arbit_ff;
    assign dummy_i_arbit = arb_done && !qp_avail[sel_qp];

    always @(posedge clk or negedge rst_n)
	    begin
            if (~rst_n)
                dummy_i_arbit_ff <= 1'b0;
            else if (dummy_i_arbit)
                dummy_i_arbit_ff <= !dummy_i_arbit_ff;
            else if (!dummy_i_arbit)
                dummy_i_arbit_ff <= 1'b0;
        end

    generate 
        if (MAX_QP <= 8)
            begin
                // selcted qp: arbitrated qp
                always @(posedge clk or negedge rst_n)
                    begin
                        if (~rst_n)
                            sel_qp <= {QP_PTR_WIDTH {1'b0}};
                        else if ((initial_condition && (!arb_done)) || arbitrate)
                            begin
                                sel_qp <= sel_qp_next;		
                            end	
                    end
    
                //arbitraion_done: value selected after arbitration
                always @(posedge clk or negedge rst_n)
                    begin
                        if (~rst_n)
                            arb_done <= 1'b0;
                        else if (initial_condition || arbitrate)
                            arb_done <= |qp_avail;
                    end

                // First value to be pushed out
                always @(posedge clk or negedge rst_n)
                    begin
                        if (~rst_n)
                            initial_condition <=1'b1;
                        else if ( !( | qp_avail ) && arbitrate )
                            initial_condition <= 1'b1;
                        else if (| qp_avail && arb_done)
                            initial_condition <= 1'b0;
                        else if (((!arb_done) && (qp_avail_ff)))
                            initial_condition <= 1'b1;
                    end
    
                always @(*)
                    begin
                        qp_avail_shifted = circ_shift_ttl_arb(qp_avail, sel_qp);
                        sel_qp_next = priority_ttl_arb(qp_avail_shifted) + sel_qp;
                    end
                assign o_arbit_val = arb_done && (!arbitrate) && !dummy_i_arbit;
            end
        else 
            begin
                // First value to be pushed out
                always @(posedge clk or negedge rst_n)
                    begin
                        if (~rst_n)
                            initial_condition <=1'b1;
                        else if ( !( | qp_avail ) && arbitrate )
                            initial_condition <= 1'b1;
                        else if (| qp_avail && arb_done)
                            initial_condition <= 1'b0;
                        else if (((!arb_done) && (qp_avail_2ff)))
                            initial_condition <= 1'b1;
                    end
                assign o_arbit_val = arb_done && (!arbitrate) && !dummy_i_arbit;

                // selcted qp: arbitrated qp
                always @(posedge clk or negedge rst_n)
                    begin
                        if (~rst_n)
                            sel_qp <= {QP_PTR_WIDTH {1'b0}};
                        else if (qp_next_base_addr_proc_en_ff || arbitrate)
                        begin
                            sel_qp <= sel_qp_next;		
                        end	
                    end

                // pulse to detect 1st cycle to n cycle till arbitrate signal get asserted
                // after done to start curr_qp_offser_addr_calc
                always @(posedge clk or negedge rst_n)
                    begin
                        if (~rst_n)		
                            qp_avail_2ff <= {MAX_QP{1'b0}};
                        else 
                            qp_avail_2ff <= qp_avail_ff;
                    end    
                assign qp_seltected_pulse =  arb_done && ! arbitrate; 

                // Priority function : select the first one occurenc in input array "in_val
                // from bit 1:7; keeping first but on higest priority and 7 bit on second
                // lowest priority and 0th bit has lowest priority among all
                function [MAX_QP/8 -1:0] circ_shift;
                    input  [MAX_QP/8 -1:0] shift_val;
                    input [ QP_PTR_WIDTH -1-3:0]   shifted_with;
                    reg [MAX_QP/8 -1:0] 	  shifted_val;
                    integer 				  k;
                    reg [MAX_QP/8 -1:0] mux_in [MAX_QP/8 -1:0];
                    begin
                        mux_in[0] = shift_val;
                        for (k = 1; k < MAX_QP/8 ; k=k+1)
                            begin	
                                mux_in[k] = {mux_in[k-1][0],mux_in[k-1][MAX_QP/8-1:1]}; // circular left shift by 1
                            end	
                        circ_shift = mux_in[shifted_with];
                    end	
                endfunction

                function [2:0] priority_8_in;
                    input [7 :0] in_val;
                    integer      j;
                    begin
                        priority_8_in = {3{1'b0}};
                    for (j = 0; j < 8 ; j=j+1)
                        if (in_val[j])
                            begin	
                                priority_8_in = j; // overide privious index
                            end
                    end
                endfunction

                function [7:0] circ_shift_8_in;
                    input  [7:0] shift_val;
                    input [ 2:0] shifted_with;
                    reg [7:0]    shifted_val;
                    integer      k;
                    begin
                        shifted_val = shift_val; 
                        for (k = 1; k < 8 ; k=k+1)
                            if (shifted_with >= k)
                                begin	
                                    shifted_val = {shifted_val[0],shifted_val[8 -1:1]}; // circular left shift by 1
                                end	
                        circ_shift_8_in = shifted_val;
                    end	
                endfunction

                function [QP_PTR_WIDTH -1-3 :0] priority_param;
                    input [MAX_QP/8-1 :0] in_val;
                    integer 				 j;
                    begin
                        priority_param = { (QP_PTR_WIDTH-3){1'b0}};
                        for (j = 1; j < MAX_QP/8 ; j=j+1)
                            if (in_val[j])
                                begin	
                                    priority_param = j; // overide privious index
                                end
                    end
                endfunction


                // Architecture for more than 8 to 256 qp
                always @(posedge clk or negedge rst_n)
                    begin
                        if (~rst_n)
                            arb_done <= 1'b0;
                        else if (initial_condition || arbitrate)
                            arb_done <= qp_avail_ff;
                    end
                assign arb_done_flush = arb_done && i_elmnt_unavail[sel_qp];

                // qp group 2d array
                for (gi = 0; gi < MAX_QP/8; gi = gi +1)
                    begin
                        assign qp_avail_2d[gi] = qp_avail[(gi+1)*8-1:(gi*8)];
                    end	
                
                // qp group 2d array
                for (gi = 0; gi < MAX_QP/8; gi = gi +1)
                    begin
                        assign qp_avail_2d_combo[gi] = qp_avail_combo[(gi+1)*8-1:(gi*8)];
                    end	
	
	   
                // qp_grp_validation: to check out which qp grups has valid request
                for (gi = 0; gi < MAX_QP/8; gi = gi + 1)	   
                    begin
                        always @ (posedge clk or negedge rst_n)
                            begin 
                            if (~rst_n)
                                qp_grp_valid[gi] <= 'b0;
                            else 
                                qp_grp_valid[gi] <= | qp_avail_2d_combo[gi];
                            end
                    end

                // qp_grp_valid_shifted : 
                always @ (posedge clk or negedge rst_n)
                    begin 
                        if (~rst_n)
                            qp_grp_valid_shifted <= {QP_PTR_WIDTH{1'b0}};
                        else if (qp_seltected_pulse || qp_next_base_addr_proc_en )
                            qp_grp_valid_shifted <= circ_shift(qp_grp_valid,sel_qp[QP_PTR_WIDTH-1:3]); 
                    end

                assign qp_next_base_addr_proc_en = |qp_avail && !(qp_avail_ff);

                always @(posedge clk or negedge rst_n)
                    begin
                        if(~rst_n)
                            qp_next_base_addr_proc_en_ff <= 1'b0;
                        else 
                            qp_next_base_addr_proc_en_ff <= qp_next_base_addr_proc_en;
                    end

                // next qp base addr calc and register
                always @(*)
                    begin
                        next_qp_grp_base_addr_proc = priority_param (qp_grp_valid_shifted); // + sel_qp[QP_PTR_WIDTH-1:3] ;   
                    end
                
                always @(*)
                    begin
                        next_qp_grp_base_addr = next_qp_grp_base_addr_proc + sel_qp[QP_PTR_WIDTH-1:3];
                    end
                // Priority encoder on all qp grp to know offeset address of all qp grp
                for (gi =0 ; gi < MAX_QP/8; gi = gi +1)
                    begin
                        always @(posedge clk or negedge rst_n)
                            begin	
                                if (~rst_n)
                                    qp_avail_of_qp_grp[gi] <= 3'b0;
                                else if (qp_seltected_pulse || qp_next_base_addr_proc_en )
                                    qp_avail_of_qp_grp[gi] <= priority_8_in(qp_avail_2d[gi]);
                            end 
                    end

                // Mux to select particular next qp offset address
                assign qp_avail_of_next_qp_grp = qp_avail_of_qp_grp[next_qp_grp_base_addr]; 

                // Current offset address calc Process

                // Mux to select current qp grp out of all qp grps
                assign qp_avail_of_curr_qp_grp = qp_avail_2d[(sel_qp[QP_PTR_WIDTH-1:3])];

                //Pipe line stage
                always @(posedge clk or negedge rst_n)
                    begin
                        if(~rst_n)
                            qp_avail_of_curr_qp_grp_shifted <= 8'b0;
                        else if (qp_seltected_pulse)
                            qp_avail_of_curr_qp_grp_shifted <= qp_avail_of_curr_qp_grp <<(8- sel_qp[2:0]);
                    end
                always @(*)
                    nxt_qp_avail_of_curr_qp_grp =  priority_8_in(qp_avail_of_curr_qp_grp_shifted) + sel_qp[2:0];

                always @(*)
                    begin
                        if(nxt_qp_avail_of_curr_qp_grp != sel_qp[2:0])
                            begin  
                                next_qp_grp_offset_addr = nxt_qp_avail_of_curr_qp_grp;
                                sel_qp_next = {sel_qp[QP_PTR_WIDTH-1:3],next_qp_grp_offset_addr};
                            end
                        else
                        begin
                            // next_qp_grp_offset_addr= priority_8_in(qp_avail_of_next_qp_grp); 
                            next_qp_grp_offset_addr =   qp_avail_of_next_qp_grp;                                // selected qp in next qp grp
                            sel_qp_next = {next_qp_grp_base_addr,next_qp_grp_offset_addr};
                        end
                    end // always @ begin	   
            end 
    endgenerate
endmodule 




