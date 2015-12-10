#! /usr/bin/python3

def count_twos(limit):
    """
    Accept a number and count the number of appearances of "2" digits.
    """

    count = 0

    for integer in range(limit + 1):
        for digit in str(integer):
            if digit == '2':
                count += 1

    print('%i (is the number of appearances of "2" between 0 and %i)' 
           % (count, limit))


if __name__ == "__main__":
    import sys, timeit
    
    # Sanity check CLI command.
    if len(sys.argv) >= 2:
        print(timeit.timeit("count_twos(int(sys.argv[1]))", setup="from __main__ import count_twos", number=10))
        #count_twos(int(sys.argv[1]))
    else:
        print('Please enter a number.')
