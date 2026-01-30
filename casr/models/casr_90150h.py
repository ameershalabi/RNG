from helper import *
class casr_90150h:
    def __init__(self, state, rule_vector,mode='s'):
        """
        state: list of bits (0/1)
        rule_vector: list of bits (0 = Rule 90, 1 = Rule 150)
        """
        assert len(state) == len(rule_vector)
        self.state = state[:]
        self.rules = rule_vector[:]
        self.n = len(state)
        self.mode = mode

    def step(self):
        next_state = [0] * self.n
        for i in range(self.n):
            left   = self.state[(i - 1) % self.n]
            center = self.state[i]
            right  = self.state[(i + 1) % self.n]

            if self.rules[i] == 0:
                # Rule 90
                next_state[i] = left ^ right
            else:
                # Rule 150
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
    # x"A51195"
    seed = [
     1, 0, 1, 0, #5
     1, 0, 0, 1, #9
     1, 0, 0, 0, #1
     1, 0, 0, 0, #1
     1, 0, 1, 0, #5
     0, 1, 0, 1  #A
     ] 

    # x"33333B"
    rules = [
    1, 1, 0, 1, #B
    1, 1, 0, 0, #3
    1, 1, 0, 0, #3
    1, 1, 0, 0, #3
    1, 1, 0, 0, #3
    1, 1, 0, 0  #3
    ]
    casr90150h = casr_90150h(seed, rules,'p')
    print(prep_out(casr90150h.generate(20),24))

    # x"33333B"
    seed = [
    1, 1, 0, 1, #B
    1, 1, 0, 0, #3
    1, 1, 0, 0, #3
    1, 1, 0, 0, #3
    1, 1, 0, 0, #3
    1, 1, 0, 0  #3
    ]
    # x"A51195"
    rules = [
     1, 0, 1, 0, #5
     1, 0, 0, 1, #9
     1, 0, 0, 0, #1
     1, 0, 0, 0, #1
     1, 0, 1, 0, #5
     0, 1, 0, 1  #A
     ] 

    casr90150h = casr_90150h(seed, rules,'p')
    print(prep_out(casr90150h.generate(20),24))