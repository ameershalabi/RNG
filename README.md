**A collection of random number generators implemented in VHDL.**

### lfsr_rng
Folder **lfsr_rng** is a collection of random number generators that were constructed using LFSRs. I do not exactly remember where the ideas for those generators came from, but they are there now.

### mt
Folder **mt** contains an implementation of the mersenne twister random number generator. Only a seed is needed to configure the rng.

### pcg_64
Folder **pcg_64** contains several implementations of the Permuted congruential generator.

| Block               | State        | Output       | Strength
|:--------------------|:-------------|:-------------|:-------------|
| pcg_rxs_m_xs_32    | 32b | 32b |Weak|
| pcg_xsh_rr_64      | 64b | 32b | Medium|
| pcg_xsh_rs_64      | 64b | 32b |Strong|
| pcg_xsl_rr_128     | 128b | 64b |Very Strong |