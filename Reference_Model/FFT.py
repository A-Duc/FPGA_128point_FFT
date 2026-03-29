import cmath

def FFT(P):
    n = len(P)
    if (n == 1): return P;

    omega = cmath.exp(2j * cmath.pi / n)

    P_e = P[0::2]
    P_o = P[1::2]

    y_e = FFT(P_e)
    y_o = FFT(P_o)

    y = [0] * n
    half_n = n//2
    for i in range(half_n):
        step = (omega ** i) * y_o[i]

        y[i]          = y_e[i] + step
        y[i + half_n] = y_e[i] - step
        
    return y
