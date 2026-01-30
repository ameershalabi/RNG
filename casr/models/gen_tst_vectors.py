from casr_30 import *
from casr_90 import *
from casr_150 import *
from casr_90150h import *
from helper import *

def hex_to_lsb_array(hex_str, width=512):
    """
    Convert a hex string to a binary array with LSB at index 0.
    """
    # Convert hex to integer
    value = int(hex_str, 16)

    # Convert integer to binary string without '0b'
    bin_str = bin(value)[2:]

    # Pad binary string to the desired width (MSB padding)
    bin_str = bin_str.zfill(width)

    # Reverse the string so LSB is at index 0 and convert to list of ints
    bit_array = [int(bit) for bit in reversed(bin_str)]

    return bit_array



def write_vhdl_array(values, filename, indent="    "):
    """
    Write a list of VHDL hex literals to a text file
    in a copy-paste-friendly VHDL array format.
    """
    with open(filename, "w") as f:
        f.write("(\n")
        for i, val in enumerate(values):
            comma = "," if i < len(values) - 1 else ""
            f.write(f"{indent}{val}{comma}\n")
        f.write(");\n")

def generate(n_vectors,seed,rules,seed_id=''):
    casr_30_seed = seed[:64]
    casr_90_seed = seed[:128]
    casr_150_seed = seed[:256]

    casr_30_f  = f"./casr_tst_vectors/casr_seed{seed_id}_vectors_30.txt"
    casr_90_f  = f"./casr_tst_vectors/casr_seed{seed_id}_vectors_90.txt"
    casr_150_f = f"./casr_tst_vectors/casr_seed{seed_id}_vectors_150.txt"
    casr_h_f   = f"./casr_tst_vectors/casr_seed{seed_id}_vectors_h.txt"
    
    ## creat opject and give it seed
    casr30 = casr_30(casr_30_seed,'p')
    ## store results from CASR
    casr_30_v = prep_out(casr30.generate(n_vectors),64)
    ## write into vhdl-style array
    write_vhdl_array(casr_30_v, casr_30_f)
    ## append seed to end of file
    with open(casr_30_f, 'a') as file:
        file.write(bits_lsb_to_vhdl_hex(casr_30_seed)+'\n') # generate vhdl hex
        file.write("".join(str(b) for b in reversed(casr_30_seed))+'\n') # reverse seed array and print string
        file.write("".join(map(str, casr_30_seed))+'\n') # print seed array as string

    ## creat opject and give it seed
    casr90 = casr_90(casr_90_seed,'p')
    ## store results from CASR
    casr_90_v = prep_out(casr90.generate(n_vectors),128)
    ## write into vhdl-style array
    write_vhdl_array(casr_90_v, casr_90_f)
    ## append seed to end of file
    with open(casr_90_f, 'a') as file:
        file.write(bits_lsb_to_vhdl_hex(casr_90_seed)+'\n') # generate vhdl hex
        file.write("".join(str(b) for b in reversed(casr_90_seed))+'\n') # reverse seed array and print string
        file.write("".join(map(str, casr_90_seed))+'\n') # print seed array as string

    ## creat opject and give it seed
    casr150 = casr_150(casr_150_seed,'p')
    ## store results from CASR
    casr_150_v = prep_out(casr150.generate(n_vectors),256)
    ## write into vhdl-style array
    write_vhdl_array(casr_150_v, casr_150_f)
    ## append seed to end of file
    with open(casr_150_f, 'a') as file:
        file.write(bits_lsb_to_vhdl_hex(casr_150_seed)+'\n') # generate vhdl hex
        file.write("".join(str(b) for b in reversed(casr_150_seed))+'\n') # reverse seed array and print string
        file.write("".join(map(str, casr_150_seed))+'\n') # print seed array as string

    ## creat opject and give it seed
    casr90150h = casr_90150h(seed, rules,'p')
    ## store results from CASR
    casr_h_v = prep_out(casr90150h.generate(n_vectors),512)
    ## write into vhdl-style array
    write_vhdl_array(casr_h_v, casr_h_f)
    ## append seed to end of file
    with open(casr_h_f, 'a') as file:
        file.write(bits_lsb_to_vhdl_hex(seed)+'\n') # generate vhdl hex
        file.write("".join(str(b) for b in reversed(seed))+'\n') # reverse seed array and print string
        file.write("".join(map(str, seed))+'\n') # print seed array as string
        file.write(bits_lsb_to_vhdl_hex(rules)+'\n') # generate vhdl hex
        file.write("".join(str(b) for b in reversed(rules))+'\n') # reverse rules array and print string
        file.write("".join(map(str, rules))+'\n')# print rules array as string

    
#generate(100,)

# Example usage
hex_value = "285f44ab321ed5e5d7f04bb5ad4d5b981ec6f4e08d475d5f8e7dbbb955f6389dfc7ffdd5e74ef4c24f7f1722ef758ac4db33fa5e3c4d8a2c36bd0f75a4abe07d"
binary_array = hex_to_lsb_array(hex_value, width=512)
h_rule = binary_array[256:] + binary_array[:256]
generate(100,binary_array,h_rule,"1")

hex_value = "49712b8c46739a443529e0903981802d69e9721382d28cfc4a670fffeff8d0f58af5d4a3fca5c516e9e2d67f4e5e361e139180d31d7ef528c0735ff9c3f47b0d"
binary_array = hex_to_lsb_array(hex_value, width=512)
h_rule = binary_array[256:] + binary_array[:256]
generate(100,binary_array,h_rule,"2")