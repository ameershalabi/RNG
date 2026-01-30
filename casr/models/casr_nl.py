class casr_nl:
    """
    Nonlinear Hybrid CASR
    Rules:
      0 -> Rule 90
      1 -> Rule 150
      2 -> Rule 30
    """

    def __init__(self, state, rule_vector):
        assert len(state) == len(rule_vector)
        self.state = state[:]
        self.rules = rule_vector[:]
        self.n = len(state)

    def rule30(self, L, C, R):
        # Wolfram Rule 30 truth table
        return (L & ~C & ~R) | (~L & C & R) | (~L & C & ~R) | (~L & ~C & R)

    def step(self):
        next_state = [0] * self.n

        for i in range(self.n):
            L = self.state[(i - 1) % self.n]
            C = self.state[i]
            R = self.state[(i + 1) % self.n]

            rule = self.rules[i]

            if rule == 0:
                # Rule 90
                next_state[i] = L ^ R
            elif rule == 1:
                # Rule 150
                next_state[i] = L ^ C ^ R
            else:
                # Rule 30 (nonlinear)
                next_state[i] = self.rule30(L, C, R) & 1

        self.state = next_state
        return next_state

    def nonlinear_output(self):
        """
        Nonlinear output filter:
        XOR + AND mixing of distant cells
        """
        a = self.state[0]
        b = self.state[self.n // 2]
        c = self.state[-1]
        return (a ^ b) ^ (b & c)

    def generate(self, steps):
        stream = []
        for _ in range(steps):
            self.step()
            stream.append(self.nonlinear_output())
        return stream


# Example usage
if __name__ == "__main__":
    seed = [1, 0, 1, 1, 0, 1, 0, 0, 1, 1, 0]
    rules = [2, 0, 1, 2, 1, 0, 2, 0, 1, 2, 1]  # mix of 30/90/150

    casr = casr_nl(seed, rules)
    print(casr.generate(20))