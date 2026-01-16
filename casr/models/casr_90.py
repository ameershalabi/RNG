from helper import *
class casr_90:
    def __init__(self, state,mode='s'):
        """
        state: list of bits (0/1)
        """
        self.state = state[:]
        self.n = len(state)
        self.mode = mode

    def step(self):
        next_state = [0] * self.n
        for i in range(self.n):
            left  = self.state[(i - 1) % self.n]
            right = self.state[(i + 1) % self.n]
            next_state[i] = left ^ right
        self.state = next_state
        #print(next_state)
        return self.state

    def generate(self, steps, output_cell=-1):
        stream = []
        for _ in range(steps):
            self.step()
            if self.mode == 'p':
                stream.append(self.state)
            else:
                stream.append(self.state[output_cell])
            #stream.append(self.state[output_cell])
        return stream


# Example usage
if __name__ == "__main__":
    print("---------- casr90 ----------")
    # x"A51195"
    seed = [
     1, 0, 1, 0, #5
     1, 0, 0, 1, #9
     1, 0, 0, 0, #1
     1, 0, 0, 0, #1
     1, 0, 1, 0, #5
     0, 1, 0, 1  #A
     ] 
    
    casr90 = casr_90(seed,'p')
    #print(casr90.generate(20))
    print(prep_out(casr90.generate(20),24))
    # x"33333B"
    seed =  [
    1, 1, 0, 1, #B
    1, 1, 0, 0, #3
    1, 1, 0, 0, #3
    1, 1, 0, 0, #3
    1, 1, 0, 0, #3
    1, 1, 0, 0  #3
    ]
    casr90 = casr_90(seed,'p')
    #print(casr90.generate(20))
    print(prep_out(casr90.generate(20),24))