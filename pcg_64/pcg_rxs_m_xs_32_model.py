
from tabulate import tabulate
import matplotlib.pyplot as plt

def twos_comp(val, bits):
    """compute the 2's complement of int value val"""
    if (val & (1 << (bits - 1))) != 0: # if sign bit is set e.g., 8bit: 128-255
        val = val - (1 << bits)        # compute negative value
    return val

def tranc(num, length=64,dir=0):
    hex_num=hex(num)
    num_bytes=round(length/4)
    
    if dir == 0 :
        hex_trancated=hex_num[len(hex_num)-num_bytes:len(hex_num)]
    elif dir==1 :
        hex_trancated=hex_num[2:num_bytes+2]
    else:
        hex_trancated=hex_num[len(hex_num)-num_bytes:len(hex_num)]
    new_int=int("0x"+hex_trancated,16)
    return(new_int)

shift_added_value_c=4
mult_factor_c=1857494364
incr_r=3614764435
def pcg32_init(seed_r,incr_r): # initiate the pcg and return first random number
    #print("seed int = " + str(int(seed_r)))
    state_r = int(seed_r)+incr_r
    if len(bin(state_r)) > 34:
        state_r=int("0b"+bin(state_r)[-32:],2)
    #print("init seed = " + hex(state_r))
    res_pcg,new_state=RXS_M_XS(state_r)
    return res_pcg,new_state
stage_1_tab=[]
stage_2_tab=[]

def RXS_M_XS(state_r): 
    ### stage 1
    
    stage_0_v=state_r
    # do the shift of the initial state to get the number of right shifts
    stage_1_r_shfts_v=stage_0_v>>28
    
    right_shfts_v=stage_1_r_shfts_v+shift_added_value_c
    
    # shift data 
    stage_1_shifted_v = stage_0_v >> right_shfts_v
    
    # XOR initial state with shifted state
    stage_1_v = stage_0_v ^ stage_1_shifted_v
    stage_1_r =stage_1_v

    ### stage 2
    stage_2_mult_v = stage_1_r * mult_factor_c
   
    stage_2_22_r_shfts_v = stage_2_mult_v>>22
    
    gen_word_v = stage_2_mult_v ^ stage_2_22_r_shfts_v
    gen_word_v_64="0b"+("0"*(64-len(bin(gen_word_v))+2))+bin(gen_word_v)[2:]
    gen_word_v_64_d=gen_word_v_64[2:] 
    gen_word_r="0b"+gen_word_v_64_d[shift_added_value_c:16+shift_added_value_c]
    gen_word_r=int(gen_word_r,2)

    new_state_v_64="0b"+("0"*(64-len(bin(stage_2_22_r_shfts_v))+2))+bin(stage_2_22_r_shfts_v)[2:]
    state_v=int("0b"+new_state_v_64[-32:],2)

    pcg_32=gen_word_r
    new_state=state_v
    return pcg_32, new_state

def run_pcg(runs):
    pcg_r=[]
    state_r      = 0xd0f33173		# Or something seed_r-dependent
    incr_r=3614764435
    
    pcg_32_res,new_state = pcg32_init(state_r,incr_r)
    
    pcg_full_64="0b"+('0'*(64-len(bin(pcg_32_res))))+bin(pcg_32_res)[2:]
    pcg_full_32=pcg_full_64[32:]
    pcg_r.append(int("0b"+pcg_full_32,2))
    for i in range(0,runs):
        pcg_32_res,new_state = RXS_M_XS(new_state)
        prw=[hex(pcg_32_res),hex(new_state)]
        #pcg_para_tabl.append(prw)
        pcg_full_64="0b"+('0'*(64-len(bin(pcg_32_res))))+bin(pcg_32_res)[2:]
        pcg_full_32=pcg_full_64[32:]
        pcg_r.append(int("0b"+pcg_full_32,2))
    #print(tabulate(stage_1_tab,headers=['stage_0_v','r_shifts','2s complement','gen_stage_2_r', 'right_shfts_r', 'left_shfts_r']))
    #print(tabulate(stage_2_tab,headers=['gen_word_r','state_r']))
    return pcg_r
n=300
pcg_x=[]
pcg_y = []
pcg_o = run_pcg(n)
for i in range(0,n):
    pcg_x.append(i)
    pcg_y.append(pcg_o[i]/(2**16))
    print(hex(pcg_o[i]))
    
    #print(hex(pcg_y[i]))
plt.plot(pcg_x, pcg_y)

# naming the x axis
plt.xlabel('x - axis') 
# naming the y axis
plt.ylabel('y - axis')
        
# giving a_coeffints_c title to my graph
plt.title('My first graph!')
        
# function to show the plot
plt.show()

