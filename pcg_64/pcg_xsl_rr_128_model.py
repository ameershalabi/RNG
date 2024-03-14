
# THIS IS FOR PCG-XSL-RR variant
from tabulate import tabulate
import matplotlib.pyplot as plt

def twos_comp(val, bits):
    """compute the 2's complement of int value val"""
    if (val & (1 << (bits - 1))) != 0: # if sign bit is set e.g., 8bit: 128-255
        val = val - (1 << bits)        # compute negative value
    return val

def tranc(num, length=128,dir=0):
    hex_num=hex(num)
    num_bytes=length/4

    if len(hex_num[2:]) < length :
        if dir == 0 :
            hex_trancated=hex_num[len(hex_num)-round(num_bytes):len(hex_num)]
        elif dir==1 :
            hex_trancated=hex_num[2:round(num_bytes)+2]
        else:
            hex_trancated=hex_num[len(hex_num)-round(num_bytes):len(hex_num)]
        new_int=int("0x"+hex_trancated,16)
    else:
        new_int=num
    
    return(new_int)

def pcg32_init(seed_r,mult_r,incr_r): # initiate the pcg and return first random number
    print("seed int = " + str(int(seed_r)))
    state_r = int(seed_r)+incr_r
    state_r= tranc(state_r)
    print("init seed = " + hex(state_r))
    res_pcg,new_state=pcg32(state_r,mult_r,incr_r)
    return res_pcg,new_state
stage_1_tab=[]
stage_2_tab=[]

def pcg32(state_r,mult_r,incr_r): # generate pcg from a specific state of the generator
    # names of variables are same as their counter parts in the pcg_64.vhd file
    # this allowed better debugging and cross referencing of the data
    ### stage 1
    stage_0_v=state_r
    # do the shift of the initial state
    stage_0_64_l_shfts_v=stage_0_v<<64
    stage_0_122_r_shfts_v=stage_0_v>>122
    right_shfts_v=stage_0_122_r_shfts_v
    # get the XOR of the initial state and shift for the rotation funtion
    stage_1_v = stage_0_v ^ tranc(stage_0_64_l_shfts_v)
    
    # get the two's complement intyeger equivelent for the left shifting
    right_shfts_2scomplement_v=~right_shfts_v+1
    left_shfts_v = right_shfts_2scomplement_v & 63 
    # indicate the end of the first stage
    gen_stage_2_r = stage_1_v
    right_shfts_r= right_shfts_v
    left_shfts_r=left_shfts_v
    stage_1_arr=[hex(stage_0_v) ,hex(stage_0_122_r_shfts_v) ,hex(right_shfts_2scomplement_v),hex(gen_stage_2_r), str(right_shfts_r), str(left_shfts_r)]
    stage_1_tab.append(stage_1_arr)
    
    ### stage 2
    # shift the data using the shifting values from stage 1
    stage_2_rot_r_v = gen_stage_2_r >> right_shfts_r
    stage_2_rot_l_v = gen_stage_2_r << left_shfts_r
    # create the new initial state of generator by trancating
    # the multiplication and addition result to 64 bit long int
    state_mult_add_v = stage_0_v * mult_r + incr_r
    state_r = tranc(state_mult_add_v)
    # or the results of the shifting to generate the output 
    gen_word_r = stage_2_rot_r_v | stage_2_rot_l_v
    # only take the least significant 64 bits as output
    gen_word_full_128="0b"+('0'*(128-len(bin(gen_word_r))+2))+bin(gen_word_r)[2:]
    gen_word_full_64=gen_word_full_128[len(gen_word_full_128)-2-64:]
    gen_word_r=int("0b"+gen_word_full_64,0)
    stage_2_arr=[hex(gen_word_r),hex(state_r)]
    stage_2_tab.append(stage_2_arr)
    pcg_32=gen_word_r
    new_state=state_r
    return pcg_32, new_state

def run_pcg(runs):
    pcg_para_tabl=[]
    pcg_r=[]
    state_r  = 0x4d595df4d0f33173a6aec95a0479df4d # Or something seed_r-dependent
    mult_r = 6364136223846793005 #0x5851F42D4C957F2D
    incr_r  = 1442695040888963407 #0x14057B7EF767814F	# Or an arbitrary odd constant

    pcg_64_res,new_state = pcg32_init(state_r,mult_r,incr_r)
    pcg_full_64=bin(pcg_64_res)
    pcg_full_64="0b"+('0'*(128-len(bin(pcg_64_res))))+bin(pcg_64_res)[2:]

    pcg_full_64=pcg_full_64[64:]

    pcg_r.append(int("0b"+pcg_full_64,2))
    for i in range(0,runs):
        pcg_64_res,new_state = pcg32(new_state,mult_r,incr_r)
        prw=[hex(pcg_64_res),hex(new_state)]
        pcg_para_tabl.append(prw)
        # add 2 to account for the "0x" part of the hex 
        pcg_full_64="0b"+('0'*(128-len(bin(pcg_64_res))))+bin(pcg_64_res)[2:]
        # add 2 to account for the "0b" part of the hex
        pcg_full_64=pcg_full_64[64:]
        pcg_r.append(int("0b"+pcg_full_64,2))
    #print(tabulate(stage_1_tab,headers=['stage_0_v','r_shifts','2s complement','gen_stage_2_r', 'right_shfts_r', 'left_shfts_r']))
    #print(tabulate(stage_2_tab,headers=['gen_word_r','state_r']))
    return pcg_r
n=10
pcg_x=[]
pcg_y = []
pcg_o = run_pcg(n)
for i in range(0,n):
    pcg_x.append(i)
    pcg_y.append(pcg_o[i]/(2**64))
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

