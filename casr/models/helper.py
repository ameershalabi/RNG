def array2d_to_std(array2d):
    """
    Reverse order of a list of bits LSB at index 0 to MSB at index 0
    """
    new_2d_arr = []
    for arr in array2d:
        new_arr = []
        for i in arr:
            new_arr.insert(0, i)
        new_2d_arr.append(new_arr)
    return new_2d_arr

def arr2d_to_strings(arr):
    """
    Convert a list into a string
    """
    return ["".join(map(str, row)) for row in arr]

def out_2_str(arr):
    """
    Reverse order of a list of bits LSB at index 0 to MSB at index 0
    """
    return arr2d_to_strings(array2d_to_std(arr))

def bits_lsb_to_vhdl_hex(bits):
    """
    Convert a list of bits (LSB at index 0) to a VHDL hex literal.
    Pads with 0s on the MSB side if bit-length is not a multiple of 4.
    """
    if not all(b in (0, 1) for b in bits):
        raise ValueError("Input must contain only 0s and 1s")

    # Number of hex digits needed
    hex_width = (len(bits) + 3) // 4

    # Pad with zeros on MSB side
    padded_len = hex_width * 4
    padded_bits = bits + [0] * (padded_len - len(bits))

    # Convert to MSB-first binary string
    bin_str = "".join(str(b) for b in reversed(padded_bits))

    # Binary → integer
    value = int(bin_str, 2)

    # Format integer separately, then wrap in VHDL syntax
    hex_str = format(value, f"0{hex_width}X")
    return f'x"{hex_str}"'

def bin_to_vhdl_hex(bin_list, width):
    """
    Convert a list of binary strings to VHDL-style hexadecimal literals.
    """
    if width <= 0:
        raise ValueError("Width must be a positive integer")

    hex_width = (width + 3) // 4  # number of hex digits

    result = []
    for b in bin_list:
        if not set(b).issubset({"0", "1"}):
            raise ValueError(f"Invalid binary string: {b}")

        if len(b) > width:
            raise ValueError(f"Binary string longer than width ({width}): {b}")

        padded = b.zfill(width)                   # pad MSB side
        value = int(padded, 2)                    # binary → int
        hex_digits = format(value, f"0{hex_width}X")  # leading zeros

        result.append(f'x"{hex_digits}"')

    return result

def prep_out(arr,w):
    """
    Take an output and convert it into a list of hex
    """
    return bin_to_vhdl_hex(out_2_str(arr),w)

#bits = [0,1,0,1,1,1,0,0,1,0,0,1,1,1,1,0]
#print(bits_lsb_to_vhdl_hex(bits))

#print(arr2d_to_strings(array2d_to_std([[0,1,0,1,1,1,0,0,0],[0,0,0,1,1,0,1,0,1,1,1,0,1,1,0]])))

#print(out_2_str([[0,0,0,0,1,1,1,1],[1,1,1,1,0,0,0,0],[1,0,1,0,1,0,1,0]]))

#print(bin_to_vhdl_hex(out_2_str([[0,0,0,0,1,1,1,1],[1,1,1,1,0,0,0,0],[1,0,1,0,1,0,1,0]]),16))

#print(prep_out([[0,0,0,0,1,1,1,1],[1,1,1,1,0,0,0,0],[1,0,1,0,1,0,1,0]],16))