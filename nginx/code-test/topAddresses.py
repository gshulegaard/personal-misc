"""
topAddresses.py:

This module/script contains a simple function for parsing an Nginx access-log
file and returning the top 10 most frequently logged IP addresses from the log.

Returning the count of the IP address from the log is outside the scope of this
function, but would not be difficult to include.
"""

def topAddresses(fileName):
    """
    Open an Nginx access-log and return the 10 most frequently logged IP
    addresses.

    @param {string} fileName
        Name/location of the access-log to open.

    @return {list}
        Sorted (descnending) list of most frequently logged IPs. (Most -> Least)
    """

    # Create a complete list of IPs from the log.
    ip_complete = []
    with open(fileName) as f:
        for line in f.readlines():
            ip_complete.append(line.split(" ")[0])

    # Grab a set of distinct IPs.
    distinct = set(ip_complete)
    
    # Count the occurrences of each IP and create a dict tying IP (key) to count
    # (value).
    counts = {}
    for ip in distinct:
        counts[ip] = ip_complete.count(ip)

    return sorted(counts, key=counts.get, reverse=True)[:10]

    # FD: If the hash table "counts" is sufficiently large, using heapq will
    # eventually be faster than doing a Timsort on the dictionary.
    #
    # https://docs.python.org/2/library/heapq.html
    #
    # Ex:. heapq.nlargest(10, counts, key=counts.get)


if __name__ == "__main__":
    # Ex: python topAddresses.py access-log.log

    import sys

    result = topAddresses(str(sys.argv[1]))

    for item in result:
        print(item)

    # FD: I am not sure what the use case is, but I am not anticipating this
    # to be run from command line.  Using sys.argv is a quick-and-dirty testing
    # hack...if this was meant to be a command line program, I would use the
    # Python standard argparse instead.
