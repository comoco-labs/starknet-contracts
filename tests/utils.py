def str_to_felt(text):
    return int.from_bytes(text.encode(), 'big')


def felt_to_str(felt):
    return felt.to_bytes(31, 'big').decode()


def to_uint(num):
    return (num & ((1 << 128) - 1), num >> 128)


def from_uint(uint):
    return uint[0] + (uint[1] << 128)
