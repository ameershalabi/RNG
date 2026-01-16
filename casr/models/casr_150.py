from helper import *
class casr_150:
    def __init__(self, state,mode='s'):
        self.state = state[:]
        self.n = len(state)
        self.mode = mode

    def step(self):
        next_state = [0] * self.n
        for i in range(self.n):
            left   = self.state[(i - 1) % self.n]
            center = self.state[i]
            right  = self.state[(i + 1) % self.n]
            next_state[i] = left ^ center ^ right
        self.state = next_state
        return self.state

    def generate(self, steps, output_cell=-1):
        stream = []
        for _ in range(steps):
            self.step()
            if self.mode == 'p':
                stream.append(self.state)
            else:
                stream.append(self.state[output_cell])
        return stream


# Example usage
if __name__ == "__main__":
    print("---------- casr150 ----------")
    # x"A51195"
    seed = [
     1, 0, 1, 0, #5
     1, 0, 0, 1, #9
     1, 0, 0, 0, #1
     1, 0, 0, 0, #1
     1, 0, 1, 0, #5
     0, 1, 0, 1  #A
     ] 
    
    casr150 = casr_150(seed,'p')
    print(prep_out(casr150.generate(20),24))

    # x"33333B"
    seed =  [
    1, 1, 0, 1, #B
    1, 1, 0, 0, #3
    1, 1, 0, 0, #3
    1, 1, 0, 0, #3
    1, 1, 0, 0, #3
    1, 1, 0, 0  #3
    ]
    
    casr150 = casr_150(seed,'p')
    print(prep_out(casr150.generate(20),24))