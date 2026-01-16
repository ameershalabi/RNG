from helper import *
class casr_30:
    def __init__(self, state,mode='s'):
        self.state = state[:]
        self.n = len(state)
        self.mode = mode

    def rule30(self, L, C, R):
        return (L & ~C & ~R) | (~L & C) | (~L & ~C & R)

    def step(self):
        next_state = [0] * self.n
        for i in range(self.n):
            L = self.state[(i - 1) % self.n]
            C = self.state[i]
            R = self.state[(i + 1) % self.n]
            next_state[i] = self.rule30(L, C, R) & 1
        self.state = next_state
        return next_state
    # output_cell=-1 is MSB
    # output_cell=0 is LSB
    def generate(self, steps, output_cell=-1):
        stream = []
        for _ in range(steps):
            self.step()
            if self.mode == 'p':
                stream.append(self.state)
            else:
                stream.append(self.state[output_cell])
        return stream

# Example
if __name__ == "__main__":
    ## SEED [LSB, LSB+1, ... , MSB-1, MSB]
    print("---------- casr30 serial MSB mode----------")
    # x"99"
    seed = [1, 0, 0, 1, 1, 0, 0, 1]
    casr30 = casr_30(seed)
    print(casr30.generate(20))

    # x"11"
    seed = [1, 0, 0, 0, 1, 0, 0, 0]
    casr30 = casr_30(seed)
    print(casr30.generate(20))

    # x"A5"
    seed = [1, 0, 1, 0, 0, 1, 0, 1]
    casr30 = casr_30(seed)
    print(casr30.generate(20))

    print("---------- casr30 serial LSB mode----------")
    # x"99"
    seed = [1, 0, 0, 1, 1, 0, 0, 1]
    casr30 = casr_30(seed)
    print(casr30.generate(20,0))

    # x"11"
    seed = [1, 0, 0, 0, 1, 0, 0, 0]
    casr30 = casr_30(seed)
    print(casr30.generate(20,0))

    # x"A5"
    seed = [1, 0, 1, 0, 0, 1, 0, 1]
    casr30 = casr_30(seed)
    print(casr30.generate(20,0))


    print("---------- casr_p ----------")
     # x"99"
    seed = [1, 0, 0, 1, 1, 0, 0, 1]
    casr30 = casr_30(seed,'p')
    print(prep_out(casr30.generate(20),8))


    # x"11"
    seed = [1, 0, 0, 0, 1, 0, 0, 0]
    casr30 = casr_30(seed,'p')
    print(prep_out(casr30.generate(20),8))


    # x"A5"
    seed = [1, 0, 1, 0, 0, 1, 0, 1]
    casr30 = casr_30(seed,'p')
    print(prep_out(casr30.generate(20),8))